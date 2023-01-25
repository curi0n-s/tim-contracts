// SPDX-License-Identifier: MIT

// Riffing on Hoots.xyz nftmsg @ 0x0217a10f9508939680fd0E1288d66Dc581021319 to make more gas efficient

pragma solidity >=0.8.0 <0.9.0;

import "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "lib/ERC1155D/contracts/ERC1155D.sol";
import "./base64.sol";

// next - threads within a registry? - initial sender decides whether to start a thread or just send one-off message with 1155
// options
    // tim - just message sent with main contract
    // timthread - new contract created with thread ID as title?
    // or just new metadata for existing conctract per-thread?
contract TIM is ERC1155, ReentrancyGuard, Ownable {
    using Strings for uint256;
    
    bool public paused = false;
        
    string public domain = "timsg.xyz";
    string public description = "TinyImmutableMessage";

    string public nft_name = "TIM";

    string public header = "";
    string public footer = "";

    uint256 public minPrice = 0.007 ether;

    uint256 public totalSupply; //unlimited
    uint256 public totalBurned;
    uint256 public totalMinted;

    uint256 maxLines = 15;
    uint256 maxLineLength = 20;
    
    struct Message {
        string name;
        string description;
        string[] msgLines;
    }

    mapping(uint256 => Message) public TokenIdToMessage;

    constructor() ERC1155("") {
        header = string(abi.encodePacked(
                        '<svg id="card" viewBox="0 0 200 300" xmlns="http://www.w3.org/2000/svg">',
                        '<rect x="2" y="2" rx="2" ry="2" width="196" height="296" style="fill:white;stroke:black;stroke-width:2;opacity:1"></rect>',
                        '<text style="white-space:pre;fill:rgb(15,12,29);font:normal 16px Courier, Monospace, serif;" x="7" y="17">'));

        footer = string(abi.encodePacked(
            '<rect x="3" y="245" rx="0" ry="0" width="194" height="52" style="fill:rgb(15, 12, 29);stroke-width:0;opacity:0.0;"></rect>',
            '<text style="font:bold 10px Courier, Monospace, serif;fill:rgb(88, 85, 122)" x="7" y="288">',
            domain,
            '</text>'));
      description = string(abi.encodePacked(
        domain,
        ': TIM'
      ));
    }


    function mintTo(string[] memory _stringLines, address _to, bool asAirdrop) public payable {
        string[] memory thisStringLines = new string[](maxLines);
        
        require(!paused, "Minting is paused.");
        require(_stringLines.length <= maxLines, "Need <15 array items of text.");
        
        for(uint256 i = 0; i < _stringLines.length; i++) {
            require(bytes(_stringLines[i]).length <= maxLineLength, "Line too long.");
        }

        for(uint256 i = 0; i < maxLines; i++) {
            if(i > _stringLines.length-1){
                thisStringLines[i] = " ";
            } else {
                thisStringLines[i] = _stringLines[i];
            }
        }

        Message memory newMessage = Message(
            string(abi.encodePacked(nft_name,'-',uint256(totalSupply + 1).toString())),
            description,
            thisStringLines
        );

        if (msg.sender != owner()) {
            require(msg.value>= minPrice);
        }

        TokenIdToMessage[totalSupply + 1] = newMessage; //Add Message to mapping @tokenId
        if (asAirdrop) { 
            _mint(_to, totalSupply+1, 1, "");
        } else {
            _mint(msg.sender, totalSupply+1, 1, "");
            safeTransferFrom(msg.sender, _to, totalSupply + 1 , 1, "");
        }
        ++totalMinted;
        ++totalSupply;
        
    }

    function burnMessage(uint256 _tokenId) public {
        require(balanceOf(msg.sender, _tokenId) == 1, "Only owner can burn message.");
        _burn(msg.sender, _tokenId, 1);
        ++totalBurned;
        --totalSupply;
    }

    function getSVGTextLine(uint256 _startingY, string memory _text) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<tspan x="7" y="', 
                Strings.toString(_startingY),
                '">',
                _text,
                '</tspan>'));
    }

    function getTextLinesOneThroughEight(uint256 startY, string[] memory stringLine) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                getSVGTextLine(startY, stringLine[0]),
                getSVGTextLine(startY + 20, stringLine[1]),
                getSVGTextLine(startY + 40, stringLine[2]),
                getSVGTextLine(startY + 60, stringLine[3]),
                getSVGTextLine(startY + 80, stringLine[4]),
                getSVGTextLine(startY + 100, stringLine[5]),
                getSVGTextLine(startY + 120, stringLine[6])            )
        );
    }

    function getTextLinesNineThroughFourteen(uint256 startY, string[] memory stringLine) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                getSVGTextLine(startY, stringLine[7]),
                getSVGTextLine(startY + 20, stringLine[8]),
                getSVGTextLine(startY + 40, stringLine[9]),
                getSVGTextLine(startY + 60, stringLine[10]),
                getSVGTextLine(startY + 80, stringLine[11]),
                getSVGTextLine(startY + 100, stringLine[12]),
                getSVGTextLine(startY + 120, stringLine[13])
            )
        );
    }



    function buildImage(string[] memory stringLine) private view returns (string memory) {
        return
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        header,
                        getTextLinesOneThroughEight(20, stringLine),
                        getTextLinesNineThroughFourteen(160, stringLine),
                        '</text>',
                        footer,
                        '</svg>'
                    )
                )
            );
    }

    function buildMetadata(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        Message memory currentMessage = TokenIdToMessage[_tokenId];
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                currentMessage.name,
                                '", "external_url": "https://',
                                domain,
                                '", "description":"',
                                currentMessage.description,
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                buildImage(currentMessage.msgLines),
                                '", "attributes": ',
                                "[",
                                '{"trait_type": "TIM-ID",',
                                '"value":"',
                                Strings.toString(_tokenId),
                                '"}',
                                "]",
                                "}"
                            )
                        )
                    )
                )
            );
    }

    function uri(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _tokenId <= totalSupply,
            "invalid token id"
        );
        return buildMetadata(_tokenId);
    }

    /* only owner... */
    function setPaused(bool _paused) public onlyOwner {
        require(msg.sender == owner(), "You are not the owner");
        paused = _paused;
    }

    function setMetadata(string memory _domain, string memory _name, string memory _description) public onlyOwner {
      require(msg.sender == owner(), "You are not the owner");
        description = _description;
        nft_name = _name;
        domain = _domain;
    }

    function setHeaderFooter(bytes memory _bHeader, bytes memory _bFooter) public onlyOwner {
        require(msg.sender == owner(), "You are not the owner");
        header = abi.decode(_bHeader, (string));
        footer = abi.decode(_bFooter, (string));
    }

    function setMinPrice(uint256 _newPrice) public onlyOwner {
        minPrice = _newPrice;
    }

    function withdraw() public payable onlyOwner nonReentrant {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}