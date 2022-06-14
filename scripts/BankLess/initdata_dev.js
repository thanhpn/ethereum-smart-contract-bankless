const hre = require("hardhat");
const contractAddress = "0x002CFeB551463951E8ebfEfaCd9C33EE56215EFc";
//npx hardhat run scripts/Bankless/initdata_dev.js --network bsc-testnet
async function main() {
    const ROUTER = "0x9ac64cc6e4415144c455bd8e4837fea55603e5c3"
    const WBNB = "0xae13d989dac2f0debff460ac112a837c89baa7cd"
    const DAI = "0x8a9424745056Eb399FD19a0EC26A14316684e274"
    const USDT = "0x7ef95a0fee0dd31b22626fa2e10ee6a223f8a684"
    const CAKE = "0xf9f93cf501bfadb6494589cb4b4c15de49e85d0e"
    const ETH = "0x8babbb98678facc7342735486c851abd7a0d17ca" // fake token
    const BUSD = "0x78867bbeef44f2326bf8ddd1941a4439382ef2a7" // fake token

    const RECEIVER = "0x0B10571564AB1a5094F6180ED04Bba3b1928299D"
    const USDT_10 = 10000000
    // const DAI_10 = "10000000000000000000"//10
    const DAI_10 = "1000000000000000000" //1
    const ETH_0_1 = "100000000000000000" //0.1
    const deadline = 1700000000

    const BankLess = await hre.ethers.getContractFactory('BankLess');
    const myContract = await BankLess.attach(contractAddress);
    // await myContract.initialize(50, 100, ROUTER, WBNB);
    // await myContract.createSaving(0, "10000000000000000", "0xae13d989dac2f0debff460ac112a837c89baa7cd", "0xae13d989dac2f0debff460ac112a837c89baa7cd", { value: "10000000000000000" });
    await myContract.withdrawSaving("100000000000000", 1);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });