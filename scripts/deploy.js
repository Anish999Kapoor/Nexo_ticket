const { ethers, upgrades } = require("hardhat");

const { getImplementationAddress } = require('@openzeppelin/upgrades-core');
const { parseEther } = require("@ethersproject/units");


async function main() {

   

    const customERC721_ = await ethers.getContractFactory("CustomERC721");
    const customERC721 = await customERC721_.deploy('ticket','TKT','ipfs://QmSSLnBDyn1xYc4dnjBrc7FHZf5HBV62s7VNph6tGiCQaQ/');
    await customERC721.deployed();
    console.log(`customERC721 deployed at: ${customERC721.address}`); 

  
    const tickets_ = await ethers.getContractFactory("tickets");
    const tickets = await upgrades.deployProxy(tickets_, [parseEther('0.1'), customERC721.address ] , {kind: 'uups'});
    await tickets.deployed();
    console.log(`tickets proxy deployed at: ${tickets.address}`);
  
     const ticketsImplementationAddress = await getImplementationAddress(ethers.provider, tickets.address);
    console.log(`tickets implementation deployed at: ${ticketsImplementationAddress}`); 


}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});