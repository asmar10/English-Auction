pragma solidity ^0.8.9;

interface IERC721{
    function safeTransferFrom(address from, address to, uint tokenId) external;
    function transferFrom(address, address, uint) external;
} 

error auctionNotLive();
error highestBidderCantWithdraw();
error thisNftIsAlreadyOnAuction();

contract englishAuction {
    modifier onlyHighestBidderOrSeller{
        require(msg.sender==highestBidder || msg.sender==seller,"youCantEnd");
        _;
    }

    IERC721 immutable contractAdd;
    uint public  tokenId;
    uint public highestBid;
    address public highestBidder;
    uint public  startedAt;
    uint public  endAt;
    bool public isAutionLive;
    address public immutable seller;

    mapping (address=>uint) public bidders;

    constructor (address _nft) public {
        contractAdd = IERC721(_nft);
        seller= msg.sender;
    }

    function startAuction ( uint _tokenId, uint endTime, uint _amount ) public  {
        tokenId= _tokenId;
        highestBid=_amount;
        isAutionLive= true;
        startedAt=block.timestamp;
        endAt=startedAt + endTime;
        contractAdd.transferFrom(msg.sender,address(this),tokenId);
    }

    function bid() public payable {
        if(isAutionLive==false){
            revert auctionNotLive();
        }
        if(block.timestamp < endAt){
            require(msg.value >highestBid,"Bid Higher");
            highestBid=msg.value;
            highestBidder=msg.sender;
            bidders[msg.sender] += msg.value;
        }
        else{
            revert auctionNotLive();
        }
    }

    function withdraw() public {
        require(bidders[msg.sender]!=0,"You havent bid");
        if(highestBidder==msg.sender){
            revert highestBidderCantWithdraw();
        }
        else{
            uint temp = bidders[msg.sender];
            bidders[msg.sender]=0;
            payable(msg.sender).transfer(temp);
        }
    }

    function endAuction() public onlyHighestBidderOrSeller {
        require(endAt<block.timestamp,"Theres Still time");
        isAutionLive=false;

        if(highestBidder==address(0)){
            contractAdd.transferFrom(address(this), seller, tokenId);
        }
        else{
            contractAdd.transferFrom(address(this), highestBidder, tokenId);
            payable(seller).transfer(highestBid);
   
        }  
    }
}

