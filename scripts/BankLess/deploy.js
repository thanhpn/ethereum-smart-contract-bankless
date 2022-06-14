const hre = require("hardhat");
const { getImplementationAddress } = require("@openzeppelin/upgrades-core");

async function main() {
    //npx hardhat run scripts/Bankless/deploy.js --network bsc-testnet
    const BankLess = await hre.ethers.getContractFactory("BankLess");
    const tokenContract = await upgrades.deployProxy(BankLess, [50, 100, "0x10ED43C718714eb63d5aA57B78B54704E256024E", "0xae13d989dac2f0debff460ac112a837c89baa7cd"]);
    await tokenContract.deployed();
    console.log("BankLess deployed to:", tokenContract.address);

    try {
        const implAddress = await getImplementationAddress(
            tokenContract.provider,
            tokenContract.address
        );
        await hre.run("verify:verify", { address: implAddress });
        console.log("BankLess verified to:", implAddress);
    } catch (e) {

    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
//npx hardhat run scripts/BankLess/deploy.js --network mainnet
// dev: 0x87165E4904D2ffd9B63D337d0f16c7Bd96F01975