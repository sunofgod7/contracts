// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Nft is ERC721Enumerable,Ownable{
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;

  address public marketplace;

  struct NftItem {
    uint256 id;
    address creator;
    string uri;
  }
  mapping(uint256 => NftItem) public NftItems; 
  
  mapping(address => uint256) public UserNftCount; 
  struct MarketItem {
          uint256 tokenId;
          address payable creator;
          address payable owner;
          uint256 price;
          uint256 startDate;
          uint256 endDate;
          bool sold;
          bool canceled;
  }
  mapping(uint256 => MarketItem) public MarketItems;

  struct SellItem {
          uint256 marketItemId;
          uint256 tokenId;
          address payable buyerAddress;
          uint256 price;
  }
  mapping(uint256 => SellItem[]) private SellItems;
  
  constructor () ERC721("LastNftToken", "LNT") {}
  
  function createNft(address payable creator,uint256 quantity, string memory uri) onlyOwner public returns (uint256){
      _tokenIds.increment();
      uint256 newItemId = _tokenIds.current();
      _safeMint(msg.sender, newItemId);
      approve(address(this), newItemId);
  
      NftItems[newItemId] = NftItem(newItemId,creator,uri);
      MarketItems[newItemId] = MarketItem(newItemId,creator,payable(address(this)),0,0,0,true,true);
      UserNftCount[creator] +=1;
      return newItemId;
  }  
  
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
    return NftItems[tokenId].uri;
  }
  
  function fetchUserNfts(address _wallet_address)  public view returns(NftItem[] memory,uint256 totalCount){
        uint totalItemCount = _tokenIds.current();
        uint itemCount = UserNftCount[_wallet_address];
        uint currentIndex = 0;
        NftItem[] memory items = new NftItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (NftItems[i + 1].creator == _wallet_address) 
            {
                uint currentId = i + 1;
                NftItem storage currentItem = NftItems[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return (items,itemCount);
  }
  
  function  All_Nfts()  public view returns(NftItem[] memory,uint256 totalCount){
        uint totalItemCount = _tokenIds.current();
        uint currentIndex = 0;
        NftItem[] memory items = new NftItem[](totalItemCount);
        for (uint i = 0; i < totalItemCount; i++) {
                uint currentId = i + 1;
                NftItem storage currentItem = NftItems[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
        }
        return (items,totalItemCount);
  }
  
  function TransferNft(address from,address to,uint256 tokenId,uint256 amount,bytes memory data) public virtual {
      address creator = NftItems[tokenId].creator;
      transferFrom(from, to, tokenId);
      NftItems[tokenId].creator = to;
      UserNftCount[creator] -=1;
      UserNftCount[to] +=1;
       
  } 

  function sell_Nft(uint256 tokenId,uint256 sellPrice,uint256 startDate,uint256 endDate) public returns(bool){
       require(msg.sender == MarketItems[tokenId].creator , "");
       MarketItems[tokenId].price = sellPrice;
       MarketItems[tokenId].startDate = startDate;
       MarketItems[tokenId].endDate = endDate;
       MarketItems[tokenId].sold = false;
       MarketItems[tokenId].canceled = false;
      return true;
  }


  function setNftOffer(uint256 tokenId,uint256 price) public payable returns (bool){
    require(msg.value > 0,"The price must be greater than zero ");
    require(msg.value >=  price,"The amount sent is incorrect");
    require(MarketItems[tokenId].sold == false  && MarketItems[tokenId].canceled == false ,"This item is not active for sale");
    require(block.timestamp >= MarketItems[tokenId].startDate && block.timestamp <= MarketItems[tokenId].endDate,"This item is not active for sale");
    SellItems[tokenId].push(SellItem(tokenId,tokenId,payable(msg.sender),price));
    return true;
  }

  function getNftOffers(uint256 tokenId) public view returns(SellItem[] memory,uint256 totalCount){
    uint totalItemCount = SellItems[tokenId].length;
    SellItem[] memory items = new SellItem[](totalItemCount);
    for(uint i = 0; i < totalItemCount; i++){
          SellItem storage currentItem = SellItems[tokenId][i];
          items[i] = currentItem;
        
     }
     return (items,totalItemCount); 
  }

  function accept_NftOffer(uint256 tokenId,uint256 offer_id) public returns(bool){
       require(SellItems[tokenId][offer_id].marketItemId > 0,"");
       address payable seller_address = MarketItems[tokenId].creator;
       address payable buyer_address =SellItems[tokenId][offer_id].buyerAddress;
       TransferNft(msg.sender,buyer_address, tokenId,1,"");
       seller_address.transfer(SellItems[tokenId][offer_id].price);
       MarketItems[tokenId].creator = buyer_address;
       MarketItems[tokenId].sold = true;
       MarketItems[tokenId].canceled = true;
       return true;
  }

  function getBalance() public view returns (uint) {
        return address(this).balance;
  }
}