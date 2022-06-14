pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interface/IUniswapV2Router02.sol";

contract BankLess is
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20;
    using SafeMath for uint256;

    struct SavingTransaction {
        uint256 lockTime;
        uint16 rate;
        uint256 depositTime;
        uint256 amount;
        address owner;
        address tokenAddress;
        address interestTokenAddress;
    }

    struct LoanTransaction {
        uint256 lockTime;
        uint16 rate;
        uint256 loanTime;
        uint256 loanAmount;
        address loanToken;
        uint256 mortgageAmount;
        address mortgageToken;
        address owner;
    }
    // pause swap
    bool public pause;
    uint16 public baseInterestRate;
    uint16 public baseLoanInterestRate;
    uint256 public mstMonthlyEmission;
    address public router;
    address public WETH;
    address[] pathSwap;

    // mapping wallet => transaction counter;
    mapping(address => uint256) walletTransCounter;
    uint256 transactionId;
    mapping(uint256 => SavingTransaction) public savingTransactions;
    mapping(uint256 => LoanTransaction) public loanTransactions;

    // constructor
    function initialize(
        uint16 _baseInterestRate,
        uint16 _baseLoanInterestRate,
        address _router,
        address _WETH
    ) public initializer {
        __Context_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        pause = false;
        baseInterestRate = _baseInterestRate;
        baseLoanInterestRate = _baseLoanInterestRate;
        router = _router;
        WETH = _WETH;
    }

    function setRouterAddress(address _router) external onlyOwner {
        require(address(_router) != address(0), "INVALID_INPUT");
        router = _router;
    }

    function setPathAddress(address[] calldata _pathSwap) external onlyOwner {
        require(pathSwap.length > 0, "INVALID_INPUT");
        pathSwap = _pathSwap;
    }

    function setPause(bool _pause) external onlyOwner {
        pause = _pause;
    }

    /**
     * get amount available for loan
     */
    function estimateLoanAmount(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) public view returns (uint256 amountOut) {
        require(_amountIn > 0, "INVALID_AMOUNT_IN");

        address[] memory swaps = new address[](2);
        swaps[0] = _tokenIn;
        swaps[1] = _tokenOut;

        uint256[] memory amounts = IUniswapV2Router02(router).getAmountsOut(
            _amountIn,
            swaps
        );
        amountOut = amounts[amounts.length - 1].mul(50).div(100);
    }

    /**
     * @notice
     */
    function createSaving(
        uint256 _locktime,
        uint256 _amountIn,
        address _token,
        address _interestToken
    ) external payable nonReentrant {
        require(!pause, "Paused");
        require(_amountIn > 0, "INVALID_AMOUNT_IN");

        if (_token == WETH) {
            require(msg.value == _amountIn, "INVALID_AMOUNT");
        } else {
            bool transferResult = IERC20(_token).transferFrom(
                _msgSender(),
                address(this),
                _amountIn
            );
            require(transferResult, "TRANSFER");
        }

        SavingTransaction memory saving = SavingTransaction(
            _locktime,
            baseInterestRate,
            block.timestamp,
            _amountIn,
            _msgSender(),
            _token,
            _interestToken
        );
        transactionId += 1;
        savingTransactions[transactionId] = saving;

        emit NewLoan(transactionId, _msgSender(), _amountIn);
    }

    /**
     * @notice
     */
    function withdrawSaving(uint256 _amountOut, uint256 _savingId)
        external
        nonReentrant
    {
        require(!pause, "Paused");

        SavingTransaction memory saving = savingTransactions[_savingId];
        require(saving.amount >= _amountOut, "AMOUNT");
        require(saving.owner == _msgSender(), "OWNER");
        require(
            block.timestamp >= saving.lockTime + saving.depositTime,
            "LOCK TIME"
        );
        uint256 interestAmount = (
            ((saving.amount *
                saving.rate *
                (block.timestamp - saving.depositTime)) / 31536000)
        ) / 10000;
        if (saving.interestTokenAddress != saving.tokenAddress) {
            address[] memory swaps = new address[](2);
            swaps[0] = saving.tokenAddress;
            swaps[1] = saving.interestTokenAddress;
            uint256[] memory amounts = IUniswapV2Router02(router).getAmountsOut(
                interestAmount,
                swaps
            );
            uint256 amountOutInterest = amounts[amounts.length - 1];
            bool transferResult = IERC20(saving.interestTokenAddress).transfer(
                address(this),
                amountOutInterest
            );
            require(transferResult, "TRANSFER");
        } else {
            if (saving.tokenAddress == WETH) {
                (bool result, ) = _msgSender().call{
                    value: interestAmount,
                    gas: 30000
                }("");
                require(result, "Failed to transfer Ether");
            } else {
                bool transferResult = IERC20(saving.interestTokenAddress)
                    .transfer(address(this), interestAmount);
                require(transferResult, "TRANSFER");
            }
        }

        if (_amountOut > 0) {
            savingTransactions[_savingId].amount -= _amountOut;
            if (saving.tokenAddress == WETH) {
                (bool result, ) = _msgSender().call{
                    value: _amountOut,
                    gas: 30000
                }("");
                require(result, "Failed to transfer Ether");
            } else {
                bool transferResult = IERC20(saving.tokenAddress).transfer(
                    _msgSender(),
                    _amountOut
                );
                require(transferResult, "TRANSFER");
            }
        }
    }

    /**
     * @notice
     */
    function createLoan(
        uint256 _locktime,
        uint256 _amountIn,
        uint256 _amountOut,
        address _tokenIn,
        address _tokenOut
    ) external nonReentrant {
        require(!pause, "Paused");
        require(pathSwap.length > 0, "INVALID_PATH");
        require(_amountOut > 0, "INVALID_AMOUNT_OUT");

        uint256 maxAmountOut = estimateLoanAmount(
            _amountIn,
            _tokenIn,
            _tokenOut
        );

        require(_amountOut <= maxAmountOut, "MAX_AMOUNT_OUT");

        bool transferInResult = IERC20(_tokenIn).transferFrom(
            _msgSender(),
            address(this),
            _amountIn
        );
        require(transferInResult, "TRANSFER_IN");

        bool transferOutResult = IERC20(_tokenOut).transfer(
            address(this),
            _amountOut
        );
        require(transferOutResult, "TRANSFER_OUT");
        LoanTransaction memory loan = LoanTransaction(
            _locktime,
            baseLoanInterestRate,
            block.timestamp,
            _amountOut,
            _tokenOut,
            _amountIn,
            _tokenIn,
            _msgSender()
        );
        transactionId += 1;
        loanTransactions[transactionId] = loan;

        // emit Swapped(_msgSender(), amountOut);
    }

    /**
     * @notice
     */
    function payLoan(
        uint256 _id,
        uint256 _amountIn,
        address _tokenOut
    ) external nonReentrant {
        require(!pause, "Paused");
        LoanTransaction memory loan = loanTransactions[_id];
        require(loan.loanToken == _tokenOut, "INVALID_TOKEN");

        uint256 interestAmount = (loan.loanAmount *
            loan.rate *
            (block.timestamp - loan.loanTime)) /
            31536000 /
            10000;

        if (_amountIn > 0) {
            bool transferInResult = IERC20(_tokenOut).transferFrom(
                _msgSender(),
                address(this),
                _amountIn
            );
            require(transferInResult, "TRANSFER_IN");
            loanTransactions[_id].loanAmount =
                loanTransactions[_id].loanAmount -
                _amountIn +
                interestAmount;
            loanTransactions[_id].loanTime = block.timestamp;
        } else {
            bool transferInResult = IERC20(loan.loanToken).transferFrom(
                _msgSender(),
                address(this),
                loan.loanAmount + interestAmount
            );
            require(transferInResult, "TRANSFER_IN");

            bool transferOutResult = IERC20(loan.mortgageToken).transfer(
                address(this),
                loan.mortgageAmount
            );
            require(transferOutResult, "TRANSFER_OUT");
            delete loanTransactions[_id];
        }
    }

    /**
     * @notice
     */
    function burnLoan(uint256 _id) external nonReentrant {
        require(!pause, "Paused");
        LoanTransaction memory loan = loanTransactions[_id];
    }

    event NewLoan(uint256 id, address receiver, uint256 amount);
    event SetTokenAddress(address token1, address token2);
    event Deposited(address sender, uint256 amount);
    event Rescued(address sender, uint256 amount);
    event DepositToken(
        address user,
        address token,
        uint256 amount,
        uint256 transId
    );
}
