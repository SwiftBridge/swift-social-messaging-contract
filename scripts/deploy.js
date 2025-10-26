const hre = require("hardhat");
const fs = require('fs');

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  const balance = await deployer.getBalance();
  
  console.log("Deploying with:", deployer.address);
  console.log("Balance:", hre.ethers.utils.formatEther(balance), "ETH\n");

  const Contract = await hre.ethers.getContractFactory("CONTRACT_NAME");
  const contract = await Contract.deploy(CONSTRUCTOR_ARGS);
  await contract.deployed();
  
  console.log("Contract deployed to:", contract.address);
  await contract.deployTransaction.wait(5);
  
  const receipt = await contract.deployTransaction.wait();
  const deploymentInfo = {
    network: "base-mainnet",
    address: contract.address,
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    blockNumber: receipt.blockNumber,
    txHash: receipt.transactionHash,
    gasUsed: receipt.gasUsed.toString()
  };
  
  fs.writeFileSync('deployment.json', JSON.stringify(deploymentInfo, null, 2));
  console.log("\nDeployment saved to deployment.json");
}

main().then(() => process.exit(0)).catch((error) => {
  console.error(error);
  process.exit(1);
});
