// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import './CustomERC721.sol';
import './ICustomERC721.sol';
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract tickets is Initializable, OwnableUpgradeable, UUPSUpgradeable{

    event ticketUpgraded(address);
    event saleStarted(uint256);
    event ticketPriceUpdated(uint256);
    event ticketPurchased(address, uint256);
    event winnerDeclared(address);
    event fundsWithdrawn(uint256);
    event contractReset();


    
    struct ticketDetails {
        address owner;
        uint256 validity;
    }

    mapping(uint256 => ticketDetails) public ticketInfo;
    mapping(address => bool) public participants;
    address[] public participant;
    address[] public winnersList;
    address public ticketAddress;
    uint256 public saleTime;
    uint256 private ticketId;
    uint256 public ticketPrice;
    uint256 public prizePool;
    uint256 public contractFunds;
    bool private winnerAnnounced;
    bool private ticketUpdated;

  
  
    function initialize(uint256 ticketPrice_, address ticketAddress_) initializer public {
        
        __Ownable_init();
        __UUPSUpgradeable_init();
        ticketPrice = ticketPrice_;
        ticketId = 1;
        ticketAddress=ticketAddress_;
        ticketUpdated = true;

    }

  
  
    //This function is called before proxy upgrade and makes sure it is authorized.
    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

    //Returns implementation address.
    function implementationAddress() external view returns (address){
        return _getImplementation();
    }
    
   
   
   
    //updates ERC721 contracts to mint tickets NFTs.
    //Requires to be updated each time when a new sale is created.
    //Does not accept same ERC721 contract address to avoid contract malfunction.
    function updateTicketAddress(address ticketAddress_) external onlyOwner{
        require(!verifySale(),'cannot change ticket address while sale is on');
        require(ticketAddress_!=ticketAddress,'cannot redeploy same contract');
        ticketAddress = ticketAddress_;
        ticketUpdated = true;

        emit ticketUpgraded(ticketAddress);

    }
    
   
   
    //Admin funtion to start a new sale.
    //funds should be withdrawn prior to start a new sale.
    //Previous sale should be over before starting a new one.
    //ERC721 contract should be updated to start a new sale.
    function startSale(uint256 saleTime_) external onlyOwner{
        require(!winnerAnnounced, 'Winner is already announced, withdraw funds first');
        require(!verifySale(),'Sale is already on');
        require(ticketUpdated,'Need to update ticket first.');
        require(saleTime_>block.timestamp,'sale time should lie in future');

        saleTime = saleTime_;

        emit saleStarted(saleTime);
    }

    
   
   
    //Admin function to update tickets price.
    //cannot access while sale is on.
    function updateTicketPrice(uint256 ticketPrice_) external onlyOwner{
        require(!verifySale(),'Cannot change ticket price while sale is on');
        ticketPrice = ticketPrice_ ;

        emit ticketPriceUpdated(ticketPrice);
    }

    
   
   
    //external function to purchase tickets NFTs price.
    function  purchaseTickets() external payable {
        require(verifySale(),'sale is off');
        require(msg.value>=ticketPrice,'Unsufficent funds');
        
        prizePool = prizePool + msg.value;

        generateTicket();

        emit ticketPurchased(msg.sender, ticketId);
    }


    //picks winner randomly acc to ticketId.
    //distribute prize to the winner.
    //only to be called by participants.
    function pickWinner() external returns(address){
        require(participants[msg.sender],'needs to be a participant');
        require(!verifySale(),'sale is going on');
        uint256 winnerId = randomId();
        address winner = ticketInfo[winnerId].owner;
        
        payable(winner).transfer(prizePool/2);
        contractFunds = contractFunds + prizePool/2;
        winnersList.push(winner);
        winnerAnnounced = true;
        reset();

        emit winnerDeclared(winner);
        return winner;


     }


    
     //allows withdrawal of contract funds. 
     //can be withdrawn only when winner prize is distributed.
     function withdrawFunds(uint256 amount, address payable receiver) external onlyOwner{
        require(!verifySale(),'cannot withdraw while Sale is on');
        require(winnerAnnounced,'cannot withdraw until winner is announced');
        require(receiver != address(0));
        require(amount != 0 && amount<=contractFunds);
        receiver.transfer(amount);
        
        contractFunds = contractFunds-amount;
        winnerAnnounced = false;

        emit fundsWithdrawn(amount);
    }
    
    
    
   
    //internal function to mint NFTs and save metadata.
    function generateTicket() private {
        
        ICustomERC721(ticketAddress).mint(msg.sender,ticketId);
        
        ticketDetails memory ticketdetails = ticketDetails(msg.sender,saleTime);
        ticketInfo[ticketId] = ticketdetails;
        
        participants[msg.sender]=true;
        participant.push(msg.sender);
        ticketId++;


    }
   
   
   
    //generate random ticketIDs.
    //Unsafe Method! Oracle should be used instead.
    function randomId() private view returns(uint256){
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % ticketId;
    }
   
   
   
   
    function verifySale() private view returns(bool){
        return (block.timestamp<saleTime);
    } 
    
  
   
   
    //Resests the contract once a sale is complete.
    function reset() private{
        saleTime = 0;
        ticketId = 1;
        prizePool = 0;
        ticketUpdated = false;
       
        for(uint i=0; i<participant.length; i++){
            participants[participant[i]] = false;
        }

        delete participant;

        emit contractReset();
    }
    
  
  
    fallback() external payable{ 
    }

  
  
    receive() external payable{}

  
  
    //only for testing purposes!
    //Not to be included in original code!!
    function endSale() external onlyOwner{
        saleTime = 0;
    }
}
