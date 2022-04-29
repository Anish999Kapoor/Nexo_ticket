const { ethers, upgrades } = require("hardhat");

const { getImplementationAddress } = require('@openzeppelin/upgrades-core');
const { parseEther } = require("@ethersproject/units");


async function main() {

    const tickets_2_ = await ethers.getContractFactory("tickets");
        tickets_2 = await upgrades.deployProxy(tickets_2_, [parseEther('0.1'), customERC721.address ] , {kind: 'uups'});
        await tickets_2.deployed();

        const ticketsV2_ = await ethers.getContractFactory("tickets_V2");
        const ticketsV2 = await upgrades.upgradeProxy(tickets_2.address, ticketsV2_);
        console.log("tickets upgraded")

        implementationAddress = await getImplementationAddress(ethers.provider, tickets_2.address);
        console.log('tickest upgraded implementation address: ' + implementationAddress);


}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});