const hre = require("hardhat");

//npx hardhat verify --network bsc-testnet
//npx hardhat run scripts/Bankless/upgrade.js --network bsc-testnet 
async function main() {
    const BankLess = await hre.ethers.getContractFactory("BankLess");
    const contractAddress = "0x002CFeB551463951E8ebfEfaCd9C33EE56215EFc";

    console.log("Upgrading BankLess...");
    const contractUpgrade = await upgrades.upgradeProxy(contractAddress, BankLess);
    await contractUpgrade.deployed();

    console.log("contractUpgrade upgraded");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
//npx hardhat run scripts/BankLess/upgrade.js --network mainnet