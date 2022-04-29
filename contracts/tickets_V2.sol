// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import './CustomERC721.sol';
import './ICustomERC721.sol';
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract tickets_V2 is Initializable, OwnableUpgradeable, UUPSUpgradeable{

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

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}


    function implementationAddress() external view returns (address){
        return _getImplementation();
    }
    
     function verifySale() private view returns(bool){
        return (block.timestamp<saleTime);
    } 
    
    function updateTicketAddress(address ticketAddress_) external onlyOwner{
        require(!verifySale(),'cannot change ticket address while sale is on');
        require(ticketAddress_!=ticketAddress,'cannot redeploy same contract');
        ticketAddress = ticketAddress_;
        ticketUpdated = true;

    }
    
    function startSale(uint256 saleTime_) external onlyOwner{
        require(!winnerAnnounced, 'Winner is already announced, withdraw funds first');
        require(!verifySale(),'Sale is already on');
        require(ticketUpdated,'Need to update ticket first.');
        saleTime = saleTime_;
    }

    function updateTicketPrice(uint256 ticketPrice_) external onlyOwner{
        require(!verifySale(),'Cannot change ticket price while sale is on');
        ticketPrice = ticketPrice_ ;
    }

    function  purchaseTickets() public payable {
        require(verifySale(),'sale is off');
        require(msg.value>=ticketPrice,'Unsufficent funds');
        
        //payable(address(this)).transfer(msg.value);
        prizePool = prizePool + msg.value;

        generateTicket();
    }

    function generateTicket() private {
        
        ICustomERC721(ticketAddress).mint(msg.sender,ticketId);
        
        ticketDetails memory ticketdetails = ticketDetails(msg.sender,saleTime);
        ticketInfo[ticketId] = ticketdetails;
        
        participants[msg.sender]=true;
        participant.push(msg.sender);
        ticketId++;


    }

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

        return winner;

        
    }

    function randomId() private view returns(uint256){
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % ticketId;
    }

    
     function withdrawFunds(uint256 amount, address payable receiver) external onlyOwner{
        require(!verifySale(),'cannot withdraw while Sale is on');
        require(winnerAnnounced,'cannot withdraw until winner is announced');
        require(receiver != address(0));
        require(amount != 0 && amount<=contractFunds);
        receiver.transfer(amount);
        
        contractFunds = contractFunds-amount;
        winnerAnnounced = false;
    }
    
    
    
    function reset() private{
        saleTime = 0;
        ticketId = 1;
        prizePool = 0;
        ticketUpdated = false;
       
        for(uint i=0; i<participant.length; i++){
            participants[participant[i]] = false;
        }

        delete participant;
    }
    
    fallback() external payable{ 
        // prizePool = prizePool + uint256(msg.value);
    }

    function endSale() external onlyOwner{
        saleTime = 0;
    }
}
