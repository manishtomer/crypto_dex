pragma solidity ^0.4.4;

import "./owned.sol";
import "./FixedSupplyToken.sol";

contract Exchange is owned {

    /////////////////////////
    ///  Data structures  ///
    /////////////////////////

    struct Offer {

        uint amount;
        address who;

    }

    struct OrderBook {

        uint higherPrice;
        uint lowerPrice;

        mapping(uint => Offer) offers;

        uint offers_key;
        uint offers_length;

    }

    struct Token {

        address tokenContract;
        string symbolName;

        mapping(uint => OrderBook) buyBook;
        uint curBuyPrice;
        uint lowestBuyPrice;
        uint amountBuyPrices;

        mapping(uint => OrderBook) sellBook;
        uint curSellPrice;
        uint highestSellPrice;
        uint amountSellPrices;

    }

    //max 255 tokens supported
    mapping (uint8 => Token) tokens;
    uint8 symbolNameIndex;

    /////////////////////////
    /////    Balances   /////
    /////////////////////////

    mapping (address => mapping (uint8 => uint)) tokenBalancesForAddress;
    mapping (address => uint) balanceEthforAddress;


    /////////////////////////
    ///////  Events   ///////
    /////////////////////////

    event TokenDeposit(address indexed _from, uint indexed _symbolIndex, uint _amount, uint _timestamp);
    event TokenWithdraw(address indexed _to, uint indexed _symbolIndex, uint _amount, uint _timestamp);
    event EtherDeposit(address indexed _from, uint _amount, uint _timestamp);
    event EtherWithdraw(address indexed _to, uint _amount, uint _timestamp);

    ///////////////////////////////////
    // Deposits and Withdrawal Ether //
    ///////////////////////////////////

    function depositEther() public payable {
        require(balanceEthforAddress[msg.sender] + msg.value >= balanceEthforAddress[msg.sender]);
        balanceEthforAddress[msg.sender] += msg.value;
        emit EtherDeposit(msg.sender, msg.value, now);
    }

    function withdrawEther(uint amountInWei) public {
        require(balanceEthforAddress[msg.sender] - amountInWei >= 0);
        require(balanceEthforAddress[msg.sender] - amountInWei <= balanceEthforAddress[msg.sender]);
        balanceEthforAddress[msg.sender] -= amountInWei;
        msg.sender.transfer(amountInWei);
        emit EtherWithdraw(msg.sender, amountInWei, now);
    }

    function getEthBalanceInWei() public view returns (uint) {
        return balanceEthforAddress[msg.sender];
    }

    ////////////////////////////
    //// Token Management  /////
    ////////////////////////////

    function addToken(string symbolName, address erc20TokenAddress) public onlyOwner {
        require(!hasToken(symbolName));
        symbolNameIndex++;
        tokens[symbolNameIndex].tokenContract = erc20TokenAddress;
        tokens[symbolNameIndex].symbolName = symbolName;

    }

    function hasToken(string symbolName) public view returns(bool) {
        uint8 index = getSymbolIndex(symbolName);
        if (index == 0)
            return false;
        else
            return true;
    }

    function getSymbolIndex(string symbolName) public view returns (uint8) {
        for (uint8 i = 1; i <= symbolNameIndex; i++) {
            if (stringsEqual(tokens[i].symbolName, symbolName)) {
                return i;
            }
        }
        return 0;
    }

    function getSymbolIndexorThrow(string symbolName) public view returns (uint8) {
        uint8 index = getSymbolIndex(symbolName);
        require(index > 0);
        return index;
    }

    function stringsEqual(string storage _a, string memory _b) internal view returns (bool) {
        bytes storage a = bytes(_a);
        bytes memory b = bytes(_b);
        if (a.length != b.length)
            return false;
        for (uint i = 0; i < a.length; i++)
            if (a[i] != b[i])
                return false;
        return true;
    }

    ////////////////////////////////////////
    //// Deposit and Withdrawal Tokens  ////
    ////////////////////////////////////////

    function depositToken(string symbolName, uint amount) public {
        uint8 symbolNameIndex = getSymbolIndexorThrow(symbolName);
        require (tokens[symbolNameIndex].tokenContract != address(0));

        ERC20Interface token = ERC20Interface(tokens[symbolNameIndex].tokenContract);

        require(token.transferFrom(msg.sender, address(this), amount) == true);
        require(tokenBalancesForAddress[msg.sender][symbolNameIndex] + amount >= tokenBalancesForAddress[msg.sender][symbolNameIndex]);
        tokenBalancesForAddress[msg.sender][symbolNameIndex] += amount;
        emit TokenDeposit(msg.sender, symbolNameIndex, amount, now);

    }

    function withdrawToken(string symbolName, uint amount) public {

        uint8 symbolNameIndex = getSymbolIndexorThrow(symbolName);
        require (tokens[symbolNameIndex].tokenContract != address(0));

        ERC20Interface token = ERC20Interface(tokens[symbolNameIndex].tokenContract);

        require(tokenBalancesForAddress[msg.sender][symbolNameIndex] - amount >= 0);
        require(tokenBalancesForAddress[msg.sender][symbolNameIndex] - amount <= tokenBalancesForAddress[msg.sender][symbolNameIndex]);
        tokenBalancesForAddress[msg.sender][symbolNameIndex] -= amount;
        require(token.transfer(msg.sender, amount) == true);
        emit TokenWithdraw(msg.sender, symbolNameIndex, amount, now);
    }

    function getBalance(string symbolName) public view returns (uint) {
        uint8 symbolNameIndex = getSymbolIndexorThrow(symbolName);
        return tokenBalancesForAddress[msg.sender][symbolNameIndex];
    }

    ////////////////////////////////////////
    ////   New Order - Bid Order        ////
    ////////////////////////////////////////

    function buyToken(string symbolName, uint priceInWei, uint amount) public {
        uint8 tokenNameIndex = getSymbolIndexorThrow(symbolName);
        uint total_amount_ether_necessary = 0;
        uint total_amount_ether_available = 0;

        //how much ether do we need to buy
        total_amount_ether_necessary = priceInWei*amount;

        //safe math
        require(total_amount_ether_necessary >= priceInWei);
        require(total_amount_ether_necessary >= amount);
        require(balanceEthforAddress[msg.sender] >= total_amount_ether_necessary);
        require(balanceEthforAddress[msg.sender] - total_amount_ether_necessary > 0);

        //dedcut the amount from sender's balance
        balanceEthforAddress[msg.sender] -= total_amount_ether_necessary;

        if (tokens[tokenNameIndex].amountSellPrices == 0 || tokens[tokenNameIndex].curSellPrice > priceInWei) {
            // not enough tokens available at price to fulfill so add the buy order to the book

            addBuyOffer(tokenNameIndex, priceInWei, amount, msg.sender);
            // TODO emit LimitBuyOrder
        } else {
            //it's a market order, can be filled
            revert (); //TODO market order call
        }
    }

    function addBuyOffer(uint8 tokenIndex, uint priceInWei, uint amount, address who) internal {
        tokens[tokenIndex].buyBook[priceInWei].offers_length++;
        tokens[tokenIndex].buyBook[priceInWei].offers[tokens[tokenIndex].buyBook[priceInWei].offers_length] = Offer(amount, who);

        if (tokens[tokenIndex].buyBook[priceInWei].offers_length == 1) {
            tokens[tokenIndex].buyBook[priceInWei].offers_key = 1;
            //new buy order - increase the counter
            tokens[tokenIndex].amountBuyPrices++;

            uint curBuyPrice = tokens[tokenIndex].curBuyPrice;

            uint lowestBuyPrice = tokens[tokenIndex].lowestBuyPrice;

            if (lowestBuyPrice == 0 || lowestBuyPrice > priceInWei) {
                if (curBuyPrice == 0) {
                    //empty order book, add the order
                    tokens[tokenIndex].curBuyPrice = priceInWei;
                    tokens[tokenIndex].buyBook[priceInWei].higherPrice = priceInWei;
                    tokens[tokenIndex].buyBook[priceInWei].lowerPrice = 0;
                } else {
                    //tokens[tokenIndex].curBuyPrice = priceInWei;
                    tokens[tokenIndex].buyBook[lowestBuyPrice].lowerPrice = priceInWei;
                    tokens[tokenIndex].buyBook[priceInWei].higherPrice = lowestBuyPrice;
                    tokens[tokenIndex].buyBook[priceInWei].lowerPrice = 0;
                }
                tokens[tokenIndex].lowestBuyPrice = priceInWei;
            }
            else if (curBuyPrice < priceInWei) {
                tokens[tokenIndex].curBuyPrice = priceInWei;
                tokens[tokenIndex].buyBook[curBuyPrice].higherPrice = priceInWei;
                tokens[tokenIndex].buyBook[priceInWei].lowerPrice = curBuyPrice;
                tokens[tokenIndex].buyBook[priceInWei].higherPrice = priceInWei;
            }
            else {
                //soemwhere in the middle

                uint buyPrice = tokens[tokenIndex].curBuyPrice;
                bool priceFound = false;
                while (buyPrice > 0 && !priceFound) {
                    if (
                    buyPrice < priceInWei &&
                    tokens[tokenIndex].buyBook[buyPrice].higherPrice > priceInWei
                    ) {
                        // set the lower higher oprice for the new entry
                        tokens[tokenIndex].buyBook[priceInWei].higherPrice = tokens[tokenIndex].buyBook[buyPrice].higherPrice;
                        tokens[tokenIndex].buyBook[priceInWei].lowerPrice = buyPrice;
                        // set the lower price for the higher entry
                        tokens[tokenIndex].buyBook[tokens[tokenIndex].buyBook[buyPrice].higherPrice].lowerPrice = priceInWei;
                        //set the higher price for the lower entry
                        tokens[tokenIndex].buyBook[buyPrice].higherPrice = priceInWei;

                        priceFound = true;
                    }
                    buyPrice = tokens[tokenIndex].buyBook[buyPrice].lowerPrice;
                }
            }

        }
    }

    ////////////////////////////////////////
    ////   New Order - Ask Order        ////
    ////////////////////////////////////////

    function sellToken(string symbolName, uint priceInWei, uint amount) public {
        uint8 tokenNameIndex = getSymbolIndexorThrow(symbolName);
        uint total_amount_ether_necessary = 0;
        uint total_amount_ether_available = 0;

        //how much ether do we need to buy
        total_amount_ether_necessary = priceInWei*amount;

        //safe math
        require(total_amount_ether_necessary >= priceInWei);
        require(total_amount_ether_necessary >= amount);
        require(tokenBalancesForAddress[msg.sender][tokenNameIndex] >= amount);
        require(tokenBalancesForAddress[msg.sender][tokenNameIndex] - amount >= 0);
        require(balanceEthforAddress[msg.sender] + total_amount_ether_necessary >= balanceEthforAddress[msg.sender]);

        //dedcut the amount from sender's balance
        tokenBalancesForAddress[msg.sender][tokenNameIndex] -= amount;

        if (tokens[tokenNameIndex].amountBuyPrices == 0 || tokens[tokenNameIndex].curSellPrice > priceInWei) {
            // not enough tokens available at price to fulfill so add the buy order to the book

            addSellOffer(tokenNameIndex, priceInWei, amount, msg.sender);
            // TODO emit LimitBuyOrder
        } else {
            //it's a market order, can be filled
            revert (); //TODO market order call
        }
    }

    function addSellOffer(uint8 tokenIndex, uint priceInWei, uint amount, address who) internal {
        tokens[tokenIndex].sellBook[priceInWei].offers_length++;
        tokens[tokenIndex].sellBook[priceInWei].offers[tokens[tokenIndex].sellBook[priceInWei].offers_length] = Offer(amount, who);


        if (tokens[tokenIndex].sellBook[priceInWei].offers_length == 1) {
            tokens[tokenIndex].sellBook[priceInWei].offers_key = 1;
            //we have a new sell order - increase the counter, so we can set the getOrderBook array later
            tokens[tokenIndex].amountSellPrices++;

            //lowerPrice and higherPrice have to be set
            uint curSellPrice = tokens[tokenIndex].curSellPrice;

            uint highestSellPrice = tokens[tokenIndex].highestSellPrice;
            if (highestSellPrice == 0 || highestSellPrice < priceInWei) {
                if (curSellPrice == 0) {
                    //there is no sell order yet, we insert the first one...
                    tokens[tokenIndex].curSellPrice = priceInWei;
                    tokens[tokenIndex].sellBook[priceInWei].higherPrice = 0;
                    tokens[tokenIndex].sellBook[priceInWei].lowerPrice = 0;
                } else {

                    //this is the highest sell order
                    tokens[tokenIndex].sellBook[highestSellPrice].higherPrice = priceInWei;
                    tokens[tokenIndex].sellBook[priceInWei].lowerPrice = highestSellPrice;
                    tokens[tokenIndex].sellBook[priceInWei].higherPrice = 0;
                }

                tokens[tokenIndex].highestSellPrice = priceInWei;

            }
            else if (curSellPrice > priceInWei) {
                //the offer to sell is the lowest one, we don't need to find the right spot
                tokens[tokenIndex].sellBook[curSellPrice].lowerPrice = priceInWei;
                tokens[tokenIndex].sellBook[priceInWei].higherPrice = curSellPrice;
                tokens[tokenIndex].sellBook[priceInWei].lowerPrice = 0;
                tokens[tokenIndex].curSellPrice = priceInWei;

            }
            else {
                //we are somewhere in the middle, we need to find the right spot first...

                uint sellPrice = tokens[tokenIndex].curSellPrice;
                bool weFoundIt = false;
                while (sellPrice > 0 && !weFoundIt) {
                    if (
                    sellPrice < priceInWei &&
                    tokens[tokenIndex].sellBook[sellPrice].higherPrice > priceInWei
                    ) {
                        //set the new order-book entry higher/lowerPrice first right
                        tokens[tokenIndex].sellBook[priceInWei].lowerPrice = sellPrice;
                        tokens[tokenIndex].sellBook[priceInWei].higherPrice = tokens[tokenIndex].sellBook[sellPrice].higherPrice;

                        //set the higherPrice'd order-book entries lowerPrice to the current Price
                        tokens[tokenIndex].sellBook[tokens[tokenIndex].sellBook[sellPrice].higherPrice].lowerPrice = priceInWei;
                        //set the lowerPrice'd order-book entries higherPrice to the current Price
                        tokens[tokenIndex].sellBook[sellPrice].higherPrice = priceInWei;

                        //set we found it.
                        weFoundIt = true;
                    }
                    sellPrice = tokens[tokenIndex].sellBook[sellPrice].higherPrice;
                }
            }
        }
    }

    ////////////////////////////
    /// Order Book - Bid Order//
    ////////////////////////////

    function getBuyOrderBook(string symbolName) view returns (uint [], uint []) {
        uint8 tokenNameIndex = getSymbolIndexorThrow(symbolName);
        uint[] memory arrPricesBuy = new uint[] (tokens[tokenNameIndex].amountBuyPrices);
        uint[] memory arrVolumeBuy = new uint[] (tokens[tokenNameIndex].amountBuyPrices);

        uint whilePrice = tokens[tokenNameIndex].lowestBuyPrice;
        uint counter = 0;
        if (tokens[tokenNameIndex].curBuyPrice > 0) {
            while (whilePrice <= tokens[tokenNameIndex].curBuyPrice) {
                arrPricesBuy[counter] = whilePrice;
                uint volumeAtPrice = 0;
                uint offers_key = 0;

                offers_key = tokens[tokenNameIndex].buyBook[whilePrice].offers_key;
                while (offers_key <= tokens[tokenNameIndex].buyBook[whilePrice].offers_length) {
                    volumeAtPrice += tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].amount;
                    offers_key++;
                }

                arrVolumeBuy[counter] = volumeAtPrice;
                whilePrice = tokens[tokenNameIndex].buyBook[whilePrice].higherPrice;
                counter++;
            }
        }
    }

}

