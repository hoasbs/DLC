pragma solidity 0.5.16;
import "./SafeMath.sol";
import "./IBEP20.sol";
import "./BEP20.sol";

/**
 * @dev Implementation of DLC TOKEN
 * This contract is base on the Implementation of BEP20Token and 5ROI TOKEN
 * src: https://github.com/binance-chain/BEPs/blob/master/BEP20.md
 * src: https://github.com/5roiglobal/smartcontract
 */
 

contract DLCToken is BEP20Token{
    using SafeMath for uint256;
/**
 * @dev Time Unit constant
 * convert second into human readable time unit
 */
    //Timeline
    uint constant MONTH = 2629743;

    /**
     * @dev total coin supply and decimals
     * @var DLCSUPPLY total DLC coin supply
     * @var DECIMALS Decimals of DLC TOKEN
     */

    uint256 constant DLCSUPPLY = 2500000000;
    uint8 constant DECIMALS = 18;

    /**
     * @dev ultils for Transfer and Lock
     */
    
    struct LockItem {
        uint256  releaseDate;
        uint256  amount;
    }
    
    /**
     * @dev add address of fund receiver for the initial fund allocation 
    */
    
    address private marketingWallet =   0x4fcD01Edf05b1EBD8f66638f6C9d0312Df8af4ce;
    address private teamWallet =        0xB1C594206145e3401e4005A69114134c2E2a3fB3;
    address private partnerWallet =     0x4E47FCf5908F5f88F33E7b0f558e234ABAA7C246;
    address private serviceWallet =     0x6ecaCced313Bc500aBE6E1ec34BE23888a8E777A;
    

    mapping(address => uint256) private privateSale;
    mapping (address => LockItem[]) private lockList;
   
    address[] private lockedAddressList; // list of addresses that have some fund currently or previously locked
     
    //Date map
    uint[] private quarterPublic;
    
    uint256 amount;
    uint period;
    uint unit;
    uint256 amountWithDecimal = 10 ** uint256(DECIMALS);
    constructor() public payable BEP20Token("DLCTOKEN","DLC", DLCSUPPLY, DECIMALS) {
        
        //Private sale allocation
        
        /**
         * @dev modified the amount that want to transfer 
         * @var amount enter a human friendly amount 
         */

        //Partner allocation
        amount = 250000000;         // partner wallet, 250 million coins
        BEP20Token.transfer(partnerWallet, amount * amountWithDecimal);
        
        //Team allocation
        amount = 250000000;         // team wallet, 250 million coins
        BEP20Token.transfer(teamWallet, amount * amountWithDecimal);
        
        //Marketing wallet allocation
        amount = 250000000;         // marketing wallet, 250 million coins
        BEP20Token.transfer(marketingWallet, amount * amountWithDecimal);
        
        amount = 175000000;         //unlock first 2 quarters for serviceWallet, 175 million coins 
        BEP20Token.transfer(serviceWallet, amount * amountWithDecimal);

        /**
         * @dev transfer amount according to the frequency period of a time unit
         * @var period total period repeat overtime
         * @var unit hour, month, year - could use these base constant unit declare at constant list to generate custom unit such as quarter, bi-annual,etc
         * @var percentage sent certain % fund each time
         * Total time period = period * unit
         */

        period = 20;            //Timeline for serviceWalletallocation - 20 quarters
        unit =  3* MONTH;        // 3 months = a quarter
        amount = 87500000;       // 87.5 million tokens unlocked to serviceWallet 

        for(uint i = 0; i < period; i ++) {
            quarterPublic.push(block.timestamp + i * unit);
        }
        

        //Transfer locked tokens from quarter 3 to quarter 20
    
        for(uint i = 2; i < quarterPublic.length; i ++) {
            transferAndLock(serviceWallet, amount * amountWithDecimal, quarterPublic[i]);
        }
    }
    
    /**
     * @dev transfer of token to another address.
     * always require the sender has enough balance
     * @return the bool true if success. 
     * @param _receiver The address to transfer to.
     * @param _amount The amount to be transferred.
     */

    function transfer(address _receiver, uint256 _amount) public whenNotPaused returns (bool success) {
        require(_receiver != address(0)); 
        require(_amount <= getAvailableBalance(msg.sender));
        return BEP20Token.transfer(_receiver, _amount);
    }

    /**
     * @dev transfer of token on behalf of the owner to another address. 
     * always require the owner has enough balance and the sender is allowed to transfer the given amount
     * @return the bool true if success. 
     * @param _from The address to transfer from.
     * @param _receiver The address to transfer to.
     * @param _amount The amount to be transferred.
     */
    
     
    function transferFrom(address _from, address _receiver, uint256 _amount) public whenNotPaused returns (bool) {
        require(_from != address(0));
        require(_receiver != address(0));
        require(_amount <= BEP20Token.allowance(_from, msg.sender));
        require(_amount <= getAvailableBalance(_from));
        return BEP20Token.transferFrom(_from, _receiver, _amount);
    }

    /**
     * @dev transfer of token on behalf of the owner to another address. 
     * always require the owner has enough balance and the sender is allowed to transfer the given amount
     * @return the bool true if success. 
     * @param _receiver The address to transfer to.
     * @param _amount The amount to be transferred.
     */

    function transferAndLock(address _receiver, uint256 _amount, uint256 _releaseDate) public returns (bool success) {
        //Require the transferAndLock for only few wallet address
        require(msg.sender == teamWallet || msg.sender == serviceWallet || msg.sender ==   marketingWallet || msg.sender == owner() || msg.sender == partnerWallet);
        BEP20Token._transfer(msg.sender,_receiver,_amount);
        
        if (lockList[_receiver].length==0) lockedAddressList.push(_receiver);
        
        LockItem memory item = LockItem({amount:_amount, releaseDate:_releaseDate});
        lockList[_receiver].push(item);
    
        return true;
    }
   
    // Dapp Functionality

   /**
     * @dev querry the list of address that have at least a fund locked currently or in the past
     * @return the list of all addresses 
     */

    function getLockedAddresses() public view returns (address[] memory) {
        return lockedAddressList;
    }
    
   /**
     * @dev count the number of account that have at least a fund locked currently or in the past
     * @return the number of addresses 
     */

    function getNumberOfLockedAddresses() public view returns (uint256 _count) {
        return lockedAddressList.length;
    }
        
        
   /**
     * @dev check the number address that have at least a fund locked currently
     * @return the number of addresses 
     */

    function getNumberOfLockedAddressesCurrently() public view returns (uint256 _count) {
        uint256 count=0;
        for(uint256 i = 0; i<lockedAddressList.length; i++) {
            if (getLockedAmount(lockedAddressList[i])>0) count++;
        }
        return count;
    }
        
   /**
     * @dev check the list of address that have at least a fund locked currently
     * @return the list of all addresses 
     */

    function getLockedAddressesCurrently() public view returns (address[] memory) {
        address [] memory list = new address[](getNumberOfLockedAddressesCurrently());
        uint256 j = 0;
        for(uint256 i = 0; i<lockedAddressList.length; i++) {
            if (getLockedAmount(lockedAddressList[i])>0) {
                list[j] = lockedAddressList[i];
                j++;
            }
        }
        
        return list;
    }

   /**
     * @dev check locked funds of a given address.
     * @return the total amount of locked fund in an address
     * @param lockedAddress The address to check.
     */
     
    function getLockedAmount(address lockedAddress) public view returns(uint256 _amount) {
        uint256 lockedAmount =0;
        for(uint256 j = 0; j<lockList[lockedAddress].length; j++) {
            if(block.timestamp < lockList[lockedAddress][j].releaseDate) {
                uint256 temp = lockList[lockedAddress][j].amount;
                lockedAmount += temp;
            }
        }
        return lockedAmount;
    }
    
   /**
     * @dev  check the total of locked funds at the current time
     * @return the total amount of locked fund
     */
     
    function getLockedAmountTotal() public view returns(uint256 _amount) {
        uint256 sum =0;
        for(uint256 i = 0; i<lockedAddressList.length; i++) {
            uint256 lockedAmount = getLockedAmount(lockedAddressList[i]);
            sum = sum.add(lockedAmount);
        }
        return sum;
    }
    
   /**
     * @dev check of locked funds of a given address.
     * @return the total amount 
     * @param lockedAddress The address to check.
     */
     
    function getAvailableBalance(address lockedAddress) public view returns(uint256 _amount) {
        uint256 bal = BEP20Token.balanceOf(lockedAddress);
        uint256 locked = getLockedAmount(lockedAddress);
        return bal.sub(locked);
    }
    
   /**
     * @dev  check amount circulating coins that are not locked at the current time
     * @return the total amount
     */
     
    function getCirculatingSupplyTotal() public view returns(uint256 _amount) {
        return BEP20Token.totalSupply().sub(getLockedAmountTotal());
    }
}