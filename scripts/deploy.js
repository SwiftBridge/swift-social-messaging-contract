const hre = require("hardhat");
const fs = require('fs');

async function main() {
  console.log("🚀 Deploying SocialMessaging Contract to Base Sepolia...\n");

  const [deployer] = await hre.ethers.getSigners();
  console.log("📝 Deploying with account:", deployer.address);

  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log("💰 Account balance:", hre.ethers.formatEther(balance), "ETH\n");

  const Contract = await hre.ethers.getContractFactory("SocialMessaging");

  console.log("⏳ Deploying SocialMessaging contract...");
  const contract = await Contract.deploy();

  await contract.waitForDeployment();
  const contractAddress = await contract.getAddress();
  console.log("✅ SocialMessaging deployed to:", contractAddress);

  console.log("⏳ Waiting for 5 block confirmations...");
  const deployTx = contract.deploymentTransaction();
  await deployTx.wait(5);
  console.log("✅ Confirmed!\n");

  const receipt = await deployTx.wait();

  const deploymentInfo = {
    network: "base-sepolia",
    contractName: "SocialMessaging",
    contractAddress: contractAddress,
    deployer: deployer.address,
    chainId: 84532,
    timestamp: new Date().toISOString(),
    blockNumber: receipt.blockNumber,
    transactionHash: receipt.hash,
    gasUsed: receipt.gasUsed.toString(),
    gasPrice: receipt.gasPrice.toString()
  };

  fs.writeFileSync('deployment.json', JSON.stringify(deploymentInfo, null, 2));

  console.log("📄 Deployment info saved to deployment.json\n");
  console.log("═══════════════════════════════════════");
  console.log("🎉 DEPLOYMENT SUCCESSFUL!");
  console.log("═══════════════════════════════════════");
  console.log("Contract:", contractAddress);
  console.log("Gas Used:", receipt.gasUsed.toString());
  console.log("═══════════════════════════════════════\n");

  return contract;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });
