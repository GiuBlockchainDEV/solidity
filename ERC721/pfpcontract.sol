// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

//  _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _                         
// |   ____  _          ____                 |
// |  / ___|(_) _   _  |  _ \   ___ __   __  |
// | | |  _ | || | | | | | | | / _ \\ \ / /  |
// | | |_| || || |_| | | |_| ||  __/ \ V /   |
// |  \____||_| \__,_| |____/  \___|  \_/    |
// | _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ | 

import "./interface.sol";
import "./contract.sol";
import "./abstract.sol";
import "./library.sol";

//Giuliano Neroni DEV
//https://www.giulianoneroni.com/

contract degenNFT is ERC721A, Ownable, ReentrancyGuard {

    struct company_link{
        string id_company; //STATE + VAT number (VT) or company number (CN) -> IT/VT/11292211007 or UK/CN/13424753
        uint256 timestamp;}

    mapping(uint => mapping(uint => company_link)) public link;
    mapping(uint => uint) public linked_company;

    using Strings for uint256;

    string public uriPrefix = "";
    string public uriSuffix = ".json";

    uint256 public costWhitelist = 0.0001 ether;
    uint256 public costPublicSale = 0.0002 ether;
    uint256 public NFTminted;

    bool public paused = true;
    bool public whitelistMintEnabled = false;
    bool public revealed = false;

    mapping (address => bool) public whitelisted;
    mapping(address => uint) public minted;

    string public tokenName = "DEGEN NFT COLLECTION";
    string public tokenSymbol = "DNC";
    uint256 public maxSupply = 10420;
    uint256 public mintableSupply = 10000;
    uint256 public maxMintAmountPerTx = 200;
    string public hiddenMetadataUri = "ipfs://bafybeibgmbc3cfamhby6z43jr2pnx3s2u7f22qvbp2hiptisilfdccq3z4";

    
    constructor() ERC721A(tokenName, tokenSymbol) {
            maxSupply = maxSupply;
            setMaxMintAmountPerTx(maxMintAmountPerTx);
            setHiddenMetadataUri(hiddenMetadataUri);}

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
        require(totalSupply() + _mintAmount <= mintableSupply, "Mintable supply exceeded!");
        _;}

    modifier mintPriceCompliance(uint256 _mintAmount) {
        if(whitelistMintEnabled == true && paused == true){
            require(msg.value >= costWhitelist * _mintAmount, "Insufficient funds!");}
        if(paused == false){
            require(msg.value >= costPublicSale * _mintAmount, "Insufficient funds!");}
        _;}

    function create_link(address _wallet_address, string memory _id_company, uint256 _token_id) public onlyOwner { 
        require(check_token_owned(_wallet_address, _token_id) == 1, "Token not owned");  
        uint i = linked_company[_token_id];
        linked_company[_token_id] += 1;
        link[_token_id][i].id_company = _id_company;
        link[_token_id][i].timestamp = block.timestamp;}

    function remove_link(address _wallet_address, string memory _id_company, uint256 _token_id) public onlyOwner { 
        require(check_token_owned(_wallet_address, _token_id) == 1, "Token not owned"); 
        uint256 linked = linked_company[_token_id];
        for (uint i = 0; i <= linked; i++) {
            if(keccak256(bytes(link[_token_id][i].id_company)) == keccak256(bytes(_id_company))){
                link[_token_id][i].id_company = "removed";
                link[_token_id][i].timestamp = block.timestamp;}}}

    function check_link_id(address _wallet_address, string memory _id_company, uint256 _token_id) public view returns (uint8 _linked_company, uint256 valueReturn) { 
        require(check_token_owned(_wallet_address, _token_id) == 1, "Token not owned"); 
        uint256 linked = linked_company[_token_id];
        for (uint i = 0; i <= linked; i++) {
            if(keccak256(bytes(link[_token_id][i].id_company)) == keccak256(bytes(_id_company))){
                _linked_company = 1;
                valueReturn = i;}}         
        return (_linked_company, valueReturn);}

    function check_all_token_owned(address _wallet_address) public view returns (uint256[] memory valueReturn){
        require(totalSupply() > 0, "0 NFT Minted");
        uint256 mintedNFT = totalSupply();
        uint256 counter;
        uint256[] memory value = new uint256[](balanceOf(_wallet_address));
        for (uint i = 1; i <= mintedNFT; i++) {
            if(ownerOf(i) == _wallet_address){
                value[counter] = i;
                counter ++;}}         
        return value;}

    function check_all_company_linked(uint256 _token_id) public view returns (string[] memory valueReturn){
        require(linked_company[_token_id] > 0, "0 Linked Company");
        uint256 linkedcomp = linked_company[_token_id];
        string[] memory value = new string[](linkedcomp);
        for (uint i = 0; i < linkedcomp; i++) {
                value[i] = link[_token_id][i].id_company;}         
        return value;}

    function check_token_owned(address _wallet_address, uint256 token_id) public view returns (uint8 valueReturn){
        require(totalSupply() > 0, "0 NFT Minted");
        uint8 value;
        if(ownerOf(token_id) == _wallet_address){
                value = 1;}         
        return value;}

    function setCostWhitelist(uint256 _cost) public onlyOwner {
        costWhitelist = _cost;}

    function setCostPublicSale(uint256 _cost) public onlyOwner {
        costPublicSale = _cost;}

    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        require(!paused, 'The contract is paused!');
        minted[_msgSender()] = minted[_msgSender()] + _mintAmount;//CHECK
        require(minted[_msgSender()] <= maxMintAmountPerTx, "Max quantity reached");
        NFTminted += _mintAmount;
            _safeMint(_msgSender(), _mintAmount);}

    function burn(uint256 tokenId) public {
        _burn(tokenId, true); }

    function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
        require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
        //Minted by Owner without any cost, doesn't count on minted quantity
        NFTminted += _mintAmount;
        _safeMint(_receiver, _mintAmount);}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;}

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
        if (revealed == false) {
            return hiddenMetadataUri;}
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)): '';}
    
    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;}

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;}

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;}

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;}

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;}

    function setPaused(bool _state) public onlyOwner {
        paused = _state;}

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;}

    function whitelistAddress (address[] memory _addr) public onlyOwner() {
        for (uint i = 0; i < _addr.length; i++) {
            if(whitelisted[_addr[i]] == false){
                whitelisted[_addr[i]] = true;}}}

    function blacklistWhitelisted(address _addr) public onlyOwner() {
        require(whitelisted[_addr], "Account is already Blacklisted");
        whitelisted[_addr] = false;}

    function whitelistMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
        require(whitelisted[_msgSender()], "Account is not in whitelist");
        minted[_msgSender()] = minted[_msgSender()] + _mintAmount;//CHECK
        require(minted[_msgSender()] <= maxMintAmountPerTx, "Max quantity reached");
        NFTminted += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);}

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);}
        
    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;}}
