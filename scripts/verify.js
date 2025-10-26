const hre = require("hardhat");

async function main() {
  const deploymentInfo = require('../deployment.json');
  console.log("Verifying:", deploymentInfo.address);
  
  try {
    await hre.run("verify:verify", {
      address: deploymentInfo.address,
      constructorArguments: [CONSTRUCTOR_ARGS],
    });
    console.log("Verified!");
  } catch (error) {
    if (error.message.includes("Already Verified")) {
      console.log("Already verified!");
    } else {
      throw error;
    }
  }
}

main().then(() => process.exit(0)).catch(console.error);
