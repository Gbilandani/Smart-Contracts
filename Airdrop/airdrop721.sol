// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract AirDrop is ERC721, ERC721Enumerable, Pausable, Ownable {
    using Counters for Counters.Counter;
    address public _owner;
    uint256 public maxsupply = 5000;
    uint256 public whitemaxsupply = 1000 ;
    uint256 public whitemintid = 0;
    uint256 public tokenprice=0.0001 ether;
    uint256 public publicMintFees=0.0001 ether;
    uint256 public whiteMintFees=0.0000001 ether;
    bool private publicMintOpen = true;
    bool private whitelistMintOpen = false;
    uint256 public UserMaxTokens = 5;

    mapping(address => bool) public whitelist;

    struct Account {
        address owner;
        uint256 whiteminttoken;
        uint256 publicminttoken;
        uint256 airdroptokens;
    }
    mapping(address => Account) public MDAccount;
    

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("MyToken", "MTK") {
        _setOwner(msg.sender);
    }

    function _setOwner(address newOwner) private {
        _owner = newOwner;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "localhost:3000";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function ChangeMintWindows() public onlyOwner {
        // if(publicMintOpen==true && whitelistMintOpen==false)
        // {
        //     publicMintOpen= false;
        //     whitelistMintOpen = true;
        // }
        // else if(publicMintOpen==false && whitelistMintOpen==true)
        // {
        //     whitelistMintOpen = false;
        //     publicMintOpen= true;
        // }
        //  publicMintOpen= _publicMintOpen;
        //  whitelistMintOpen != _whitelistMintOpen;
        publicMintOpen = !publicMintOpen;
        whitelistMintOpen = !whitelistMintOpen;
    }

    function whitelistMint() public payable {
        require(whitelistMintOpen,"WhiteList Mint is Closed");
        require(whitelist[msg.sender],"You are not Whitelisted");
        require(whitemintid <= whitemaxsupply, "White Mint Limit Over");
        require(MDAccount[msg.sender].whiteminttoken<2,"Your white mint limit over, you can use public mint.");
        require(msg.value == (tokenprice + whiteMintFees), "Please Enter Correct Value to whitemint token");
        // require(totalSupply()< maxsupply, "Limit Over");
        // uint256 tokenId = _tokenIdCounter.current();
        // _tokenIdCounter.increment();
        // _safeMint(msg.sender, tokenId);
        internalMint();
        whitemintid++;
        MDAccount[msg.sender].whiteminttoken += 1;
        //payable(_owner).call{value: whiteMintFees};
        payable(_owner).transfer(whiteMintFees);
    }

    // Add Payment 
    function publicMint() public payable{
        
        require(publicMintOpen,"Public Mint is Closed");
        require(msg.value == (tokenprice + publicMintFees), "Please Enter Correct Value to publicmint token");
        //require(msg.value < 0.01 ether, "No Public Mint Available");
        // require(totalSupply()< maxsupply, "Limit Over");
        // uint256 tokenId = _tokenIdCounter.current();
        // _tokenIdCounter.increment();
        // _safeMint(msg.sender, tokenId);
        internalMint();
        MDAccount[msg.sender].publicminttoken += 1;
        //payable(_owner).call{value: publicMintFees};
        payable(_owner).transfer(publicMintFees);
        //fees(msg.sender);
    }

    function internalMint() internal {
        require(totalSupply()< maxsupply, "Limit Over");
        //require(msg.value == tokenprice, "Please Enter Correct Value to mint token");
        require((MDAccount[msg.sender].whiteminttoken + MDAccount[msg.sender].publicminttoken + MDAccount[msg.sender].airdroptokens) < UserMaxTokens ,"Your mint limit over");
        MDAccount[msg.sender].owner = msg.sender;
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function withdraw(address _addr) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_addr).transfer(balance);
    }

    
    function setWhitelist(address  addresses) public onlyOwner {
        // for(uint256 i=0; i < addresses.length; i++){
            whitelist[addresses]= true;
        // }
    }

    function AirdropActivate(address[] memory addresses) public onlyOwner {
        for(uint256 i=0; i < addresses.length; i++){
            if((MDAccount[addresses[i]].whiteminttoken + MDAccount[addresses[i]].publicminttoken + MDAccount[addresses[i]].airdroptokens) < UserMaxTokens){
            //     continue;
            // }
            // else{
                uint256 tokenId = _tokenIdCounter.current();
                _tokenIdCounter.increment();
                _safeMint(addresses[i], tokenId);
                MDAccount[addresses[i]].owner = addresses[i];
                MDAccount[addresses[i]].airdroptokens += 1;
            }
        }

    }



    function removeWhitelist(address[] calldata addresses) public onlyOwner {
        for(uint256 i=0; i < addresses.length; i++){
            whitelist[addresses[i]]= false;
        }
    }


    function ChangeUserMaxTokens(uint256 newmax) public onlyOwner {
        UserMaxTokens = newmax;
    }

    function changemaxsupply(uint256 maxi) public onlyOwner {
        maxsupply = maxi;
    }

    function changemaxWhitemint(uint256 max) public onlyOwner {
        whitemaxsupply = max;
    }

    function changeTokenPrice(uint256 price) public onlyOwner {
        tokenprice = price;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function PublicMintOpen() public view returns(bool) {
        return publicMintOpen;
    }

    function WhiteListMintOpen() public view returns(bool) {
        return whitelistMintOpen;
    }

    function MYTotalTokens() public view returns(uint256) {
        return (MDAccount[msg.sender].publicminttoken + MDAccount[msg.sender].whiteminttoken + MDAccount[msg.sender].airdroptokens);
    }
}
