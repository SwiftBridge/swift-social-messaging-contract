const hre = require("hardhat");

async function main() {
  console.log("🔍 Verifying SocialMessaging Contract on BaseScan...\n");

  // Load deployment info
  const deploymentInfo = require('../deployment.json');

  console.log("Contract address:", deploymentInfo.contractAddress);

  try {
    await hre.run("verify:verify", {
      address: deploymentInfo.contractAddress,
      constructorArguments: [],
    });

    console.log("\n✅ Contract verified successfully!");
    console.log("📊 View on BaseScan:");
    console.log(`   https://basescan.org/address/${deploymentInfo.contractAddress}#code\n`);

  } catch (error) {
    if (error.message.includes("Already Verified")) {
      console.log("✅ Contract already verified!");
      console.log("📊 View on BaseScan:");
      console.log(`   https://basescan.org/address/${deploymentInfo.contractAddress}#code\n`);
    } else {
      console.error("❌ Verification failed:", error.message);
      throw error;
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
