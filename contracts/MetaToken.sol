pragma solidity ^0.8.4;
import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract MetaToken is
    Initializable,
    OwnableUpgradeable,
    ERC20Upgradeable,
    AccessControlEnumerableUpgradeable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bool pause;

    function initialize() public initializer {
        __Ownable_init();
        __ERC20_init("Meta Token", "Meta");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of lowest token units to be burned.
     */
    function claimReward(address _to, uint256 value) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "Caller is not minter");
        require(!pause, "PAUSE");

        _mint(_to, value);
    }

    function mint(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "account is zero address");
        require(amount > 0, "amount is zero");
        _mint(account, amount);
    }

    function updatePause(bool _pause) external onlyOwner {
        pause = _pause;
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of lowest token units to be burned.
     */
    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    /**
     * @dev Can only be called by the current owner.
     * @param _wallet grant wallet address
     * @param _role role
     */
    function grantContractRole(string memory _role, address _wallet)
        external
        onlyOwner
    {
        grantRole(keccak256(abi.encodePacked(_role)), _wallet);
    }

    /**
     * @dev Can only be called by the current owner.
     * @param _wallet grant wallet address
     * @param _role role
     */
    function revokeContractRole(string memory _role, address _wallet)
        external
        onlyOwner
    {
        revokeRole(keccak256(abi.encodePacked(_role)), _wallet);
    }
}
