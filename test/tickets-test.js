const { ethers, upgrades } = require("hardhat");
const { expect } = require('chai');
const { formatEther, parseEther } = require("@ethersproject/units");
const { BigNumber } = require('@ethersproject/bignumber');
const { getImplementationAddress } = require('@openzeppelin/upgrades-core');


const provider = ethers.provider;
let snapshotId;
let implementationAddress;
let signers, owner, addr1, addr2, addr3, addr4, addr5;
let customERC721, tickets;



describe('Initiation', () => {
    it("Snapshot EVM", async function () {
        snapshotId = await provider.send("evm_snapshot");
    });

    it("Defining Generals", async function () {
        [owner, addr1, addr2, addr3, addr4, addr5] = await ethers.getSigners();
        signers = [owner, addr1, addr2, addr3, addr4, addr5];
    });
} )




describe('deploying and initializing contracts', () => {

    it("Should CustomERC721 be deployed.", async function () {
        const customERC721_ = await ethers.getContractFactory("CustomERC721");
        customERC721 = await customERC721_.deploy('ticket','TKT','ipfs://QmSSLnBDyn1xYc4dnjBrc7FHZf5HBV62s7VNph6tGiCQaQ/');
        await customERC721.deployed();

        expect( await customERC721.name()).to.equal('ticket');
}) 

    it("should tickets proxy be deployed.", async function () {
        const tickets_ = await ethers.getContractFactory("tickets");
        tickets = await upgrades.deployProxy(tickets_, [parseEther('0.1'), customERC721.address ] , {kind: 'uups'});
        await tickets.deployed();

    })

    it("Should implementation address be visible inside proxy contract.", async function () {
        implementationAddress = await getImplementationAddress(ethers.provider, tickets.address);
        const publicImplementationAddress = await tickets.implementationAddress();
        expect(implementationAddress).be.equal(publicImplementationAddress);
    });

    it("should upgrade proxy with ticketsV2", async function(){
        const tickets_2_ = await ethers.getContractFactory("tickets");
        tickets_2 = await upgrades.deployProxy(tickets_2_, [parseEther('0.1'), customERC721.address ] , {kind: 'uups'});
        await tickets_2.deployed();

        const ticketsV2_ = await ethers.getContractFactory("tickets_V2");
        const ticketsV2 = await upgrades.upgradeProxy(tickets_2.address, ticketsV2_);
        console.log("tickets upgraded")

        implementationAddress = await getImplementationAddress(ethers.provider, tickets_2.address);
        const publicImplementationAddress = await tickets_2.implementationAddress();
        expect(implementationAddress).be.equal(publicImplementationAddress);

    })
    
    it("should set ticket address in customERC721.", async function () {
        await customERC721.connect(owner).setTicket(tickets.address);
        expect(await customERC721.ticket()).to.equal(tickets.address);
    })
})




describe('factory contract', () => {
    
    it('should factory be deployed',async function(){
        const factory_ = await ethers.getContractFactory("TicketFactoryUUPS");
        factory = await factory_.deploy();
        await factory.deployed();

    });

    it('should factory deploy proxy contract', async function (){
        await factory.createTicket(parseEther('0.1'),factory.address);
        const addr = await factory.proxy_();
        console.log(addr);
    });
})




describe("tickets contract ", () => {

    it("should ticket price be correct.", async function () {
        expect(formatEther(await tickets.ticketPrice())).to.equal('0.1');
    });

    it("should not allow purchase of tickets when sale is off.", async function () {
        expect(tickets.connect(addr1).purchaseTickets(parseEther('0.1'))).to.be.revertedWith('sale is off');
    });

    it("should not allow non-admin to start sale", async function () {
        const saleTime = Math.round(new Date()/1000 + 3600);
        await expect( tickets.connect(addr1).startSale(saleTime)).to.be.revertedWith('Ownable: caller is not the owner');
    });

    it("should allow admin to start sale", async function () {
        const saleTime = Math.round(new Date()/1000 + 3600);
        await tickets.connect(owner).startSale(saleTime);
        expect(await tickets.saleTime()).to.equal(saleTime);
    })

    it("should not allow ticket NFT contract upgrade while sale is on", async function () {
       await expect(tickets.connect(owner).updateTicketAddress(customERC721.address)).to.be.revertedWith('cannot change ticket address while sale is on');
    })

    it('should allow purchase of tickets while sale is on', async function () {
        //const beforePricePool = Number (formatEther(await tickets.prizePool()));
        const buyerBalanceBeforeSale = Number (formatEther(await provider.getBalance(addr1.address)));
       const beforePricePool = await tickets.prizePool();

        await tickets.connect(addr1).purchaseTickets({value : parseEther('0.1')});

        const afterPricePool = await tickets.prizePool();
        const buyerBalanceAfterSale = Number (formatEther(await provider.getBalance(addr1.address)));

        expect(formatEther(afterPricePool) - formatEther(beforePricePool)).to.equal(0.1);
        expect(buyerBalanceBeforeSale - buyerBalanceAfterSale).to.be.closeTo(0.1,0.001);


    })

    it('should contain correct info about ticket', async function () {
        const info = await tickets.ticketInfo(1);
        expect(info.owner).to.equal(addr1.address);
    })

    it('should pick up a winner and distribute prize', async function () {

        await tickets.connect(addr2).purchaseTickets({value : parseEther('0.1')});
        await tickets.connect(addr3).purchaseTickets({value : parseEther('0.1')});
        await tickets.connect(addr4).purchaseTickets({value : parseEther('0.1')});

        const buyer1BalanceBeforeSale = Number (formatEther(await provider.getBalance(addr1.address)));
        const buyer2BalanceBeforeSale = Number (formatEther(await provider.getBalance(addr2.address)));
        const buyer3BalanceBeforeSale = Number (formatEther(await provider.getBalance(addr3.address)));
        const buyer4BalanceBeforeSale = Number (formatEther(await provider.getBalance(addr4.address)));
        const totalBuyerBalanceBeforeSale = buyer1BalanceBeforeSale + buyer2BalanceBeforeSale + buyer3BalanceBeforeSale + buyer4BalanceBeforeSale
        
        const beforePricePool = await tickets.prizePool()
        
        await tickets.connect(owner).endSale();

        await tickets.connect(addr1).pickWinner();
        const winner = await tickets.winnersList(0);
        console.log(winner);

        const afterPricePool = await tickets.prizePool();
        //console.log(formatEther(beforePricePool));
       
        const buyer1BalanceafterSale = Number (formatEther(await provider.getBalance(addr1.address)));
        const buyer2BalanceafterSale = Number (formatEther(await provider.getBalance(addr2.address)));
        const buyer3BalanceafterSale = Number (formatEther(await provider.getBalance(addr3.address)));
        const buyer4BalanceafterSale = Number (formatEther(await provider.getBalance(addr4.address)));
        const totalBuyerBalanceafterSale = buyer1BalanceafterSale + buyer2BalanceafterSale + buyer3BalanceafterSale + buyer4BalanceafterSale;

        expect(totalBuyerBalanceafterSale - totalBuyerBalanceBeforeSale).to.be.closeTo(0.2,0.01);

    })

    it('should reset contract after distributing prize', async function() {
        expect(await tickets.saleTime()).to.equal(0);
        expect(await tickets.participants(addr1.address)).to.equal(false);

    })

    it('should not allow ticket purchase prior to funds withdraw', async function() {
        expect(tickets.purchaseTickets({value: parseEther('0.1')})).to.be.revertedWith('sale is off');
    });

    it('should not allow to start sale prior to funds withdraw', async function() {
        const saleTime = Math.round(new Date()/1000 + 3600);
        await expect(tickets.startSale(saleTime)).to.be.revertedWith('Winner is already announced, withdraw funds first');
    });

    it('should allow to withdraw contract funds.', async function() {
        const fundsBeforeWithdraw = await tickets.contractFunds();
        const balBeforeWithdraw = Number (formatEther(await provider.getBalance(addr1.address)));
       
        await tickets.connect(owner).withdrawFunds(parseEther('0.1'),addr1.address);

        const fundsAfterWithdraw = await tickets.contractFunds();
        const balAfterWithdraw = Number (formatEther(await provider.getBalance(addr1.address)));

        expect(formatEther(fundsBeforeWithdraw) - formatEther(fundsAfterWithdraw)).to.be.closeTo(0.1,0.01);
        expect(balAfterWithdraw - balBeforeWithdraw).to.be.closeTo(0.1,0.01);



    })

    it('should not allow to start new sale without updating ticket NFT contract', async function (){
        const saleTime = Math.round(new Date()/1000 + 3600);
        await expect(tickets.startSale(saleTime)).to.be.revertedWith('Need to update ticket first.');
    });

    it('should upgrade ticket NFT contract', async function (){
        const customERC721_2_ = await ethers.getContractFactory("CustomERC721_V2");
        customERC721_2 = await customERC721_2_.deploy('ticket2','TKT2','0x');
        await customERC721_2.deployed();

        await(tickets.connect(owner).updateTicketAddress(customERC721_2.address));
        await customERC721.connect(owner).setTicket(tickets.address);

        expect(await tickets.ticketAddress()).to.equal(customERC721_2.address);
    });

    it('should start sale after ticket NFT contract Upgrade', async function() {
        const saleTime = Math.round(new Date()/1000 + 3600);
        await tickets.startSale(saleTime);
        expect(await tickets.saleTime()).to.equal(saleTime);
    })

})



describe('CustomERC721 Contract',() => {
    
    it('should deny direct minting access to users', async function() {
        await expect(customERC721.connect(addr1).mint(addr1.address,2)).to.be.revertedWith('Access Denied!');
    });

    it('should ticket NFTs mint through tickets contract', async function() {
        expect(await customERC721.ticketOwner(1)).to.equal(addr1.address);
    });
})