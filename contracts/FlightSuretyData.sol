pragma solidity >=0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    // address payable public dataContractAddress;
    mapping(address => uint256) private authorizedContracts;

    // airlines info
    struct Airline {
        address airlineWallet;
        bool isRegistered;
        string name;
        uint256 funded;
        uint256 votes;
    }
    mapping(address => Airline) private airlines;

    // passengers info
    struct Passenger {
        address passengerWallet;
        mapping(string => uint256) boughtFlight;
        uint256 credit;
    }
    mapping(address => Passenger) private passengers;
    address[] public passengerAddresses;

    uint256 public constant INSURANCE_PRICE_LIMIT = 1 ether;
    uint256 public constant MINIMUM_FUNDS = 10 ether;

    //multiparty variables
    uint8 private constant MULTIPARTY_MIN_AIRLINES = 4;
    uint256 public airlinesCount;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                )
                                public
    {
        contractOwner = msg.sender;
        airlinesCount = 0;
        authorizedContracts[msg.sender] = 1;
        passengerAddresses = new address[](0);

        // 	First airline is registered when contract is deployed.
        airlines[msg.sender] = Airline({
                                            airlineWallet: msg.sender,
                                            isRegistered: true,
                                            name: "UdacityAir",
                                            funded: 0,
                                            // votes: new address[](0)
                                            votes: 0
                                    });
        airlinesCount++;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational()
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /**
    * @dev Modifier that requires the calling App contract has been authorized
    */
    modifier requireIsCallerAuthorized()
    {
        require(authorizedContracts[msg.sender] == 1, "Caller is not an authorized contract");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */
    function isOperational()
                            public
                            view
                            returns(bool)
    {
        return operational;
    }

    function authorizeCaller
                            (
                                address contractAddress
                            )
                            external
                            requireContractOwner
    {
        authorizedContracts[contractAddress] = 1;
    }

     function isAuthorized
                            (
                                address contractAddress
                            )
                            external
                            view
                            returns(bool)
    {
        return(authorizedContracts[contractAddress] == 1);
    }

    function deauthorizeCaller
                            (
                                address contractAddress
                            )
                            external
                            requireContractOwner
    {
        delete authorizedContracts[contractAddress];
    }

    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */
    function setOperatingStatus
                            (
                                bool mode
                            )
                            external
                            requireContractOwner
    {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    function isActive ( address airline) public view returns(bool) {
        return(airlines[airline].funded >= MINIMUM_FUNDS);
    }

    function isRegistered ( address airline) public view returns(bool) {
        return(airlines[airline].isRegistered);
    }

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */
    function registerAirline
                            (
                                address airlineAddress,
                                string calldata name
                            )
                            external
                            requireIsOperational
                            requireIsCallerAuthorized
                            returns (bool)
    {
        require(airlineAddress != address(0), "'airlineAddress' must be a valid address.");
        require(!airlines[airlineAddress].isRegistered, "Airline is already registered.");

        if(airlinesCount < MULTIPARTY_MIN_AIRLINES){
            airlines[airlineAddress] = Airline({
                                                airlineWallet: airlineAddress,
                                                isRegistered: true,
                                                name: name,
                                                funded: 0,
                                                votes: 1
                                        });
            airlinesCount++;
        } else {
            require(vote(airlineAddress), "An error happened while voting");
        }
        return (true);
    }

    function vote (address voted) internal requireIsOperational returns(bool) {
        bool votingOK = false;
        airlines[voted].votes++;
        if (airlines[voted].votes >= airlinesCount.div(2)) {
            airlines[voted].isRegistered = true;
            airlinesCount++;
        }
        votingOK = true;
        return votingOK;
    }

    function getAirlineVotes(address airline) public view returns (uint256 votes) {
        return (airlines[airline].votes);
    }

   /**
    * @dev Buy insurance for a flight
    *
    */
    function buy
                            (
                                string calldata flightCode
                            )
                            external
                            payable
                            requireIsOperational
                            returns (uint256, address, uint256)
    {
        require(msg.sender == tx.origin, "Contracts not allowed");
        require(msg.value > 0, 'You need to pay something to buy a flight insurance');

        if(!checkIfContains(msg.sender)){
            passengerAddresses.push(msg.sender);
        }
        if (passengers[msg.sender].passengerWallet != msg.sender) {
            passengers[msg.sender] = Passenger({
                                                passengerWallet: msg.sender,
                                                credit: 0
                                        });
            passengers[msg.sender].boughtFlight[flightCode] = msg.value;
        } else {
            passengers[msg.sender].boughtFlight[flightCode] = msg.value;
        }
        if (msg.value > INSURANCE_PRICE_LIMIT) {
            msg.sender.transfer(msg.value.sub(INSURANCE_PRICE_LIMIT));
        }
    }

    function checkIfContains(address passenger) internal view returns(bool inList){
        inList = false;
        for (uint256 c = 0; c < passengerAddresses.length; c++) {
            if (passengerAddresses[c] == passenger) {
                inList = true;
                break;
            }
        }
        return inList;
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                    string calldata flightCode
                                )
                                external
                                requireIsOperational
    {
        for (uint256 c = 0; c < passengerAddresses.length; c++) {
            if(passengers[passengerAddresses[c]].boughtFlight[flightCode] != 0) {
                uint256 savedCredit = passengers[passengerAddresses[c]].credit;
                uint256 payedPrice = passengers[passengerAddresses[c]].boughtFlight[flightCode];
                passengers[passengerAddresses[c]].boughtFlight[flightCode] = 0;
                passengers[passengerAddresses[c]].credit = savedCredit + payedPrice + payedPrice.div(2);
            }
        }
    }

    function getCreditToPay() external view returns (uint256) {
        return passengers[msg.sender].credit;
    }
    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function withdraw
                            (
                                address payable insuredPassenger
                            )
                            public
                            requireIsOperational
                            returns (uint256, uint256, uint256, uint256, address, address)
    {
        require(insuredPassenger == tx.origin, "Contracts not allowed");
        require(passengers[insuredPassenger].credit > 0, "The company didn't put any money to be withdrawed by you");
        uint256 initialBalance = address(this).balance;
        uint256 credit = passengers[insuredPassenger].credit;
        require(address(this).balance > credit, "The contract does not have enough funds to pay the credit");
        passengers[insuredPassenger].credit = 0;
        insuredPassenger.transfer(credit);
        uint256 finalCredit = passengers[insuredPassenger].credit;
        return (initialBalance, credit, address(this).balance, finalCredit, insuredPassenger, address(this));
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */
    function fund
                            (
                            )
                            public
                            payable
                            requireIsOperational
    {
        uint256 currentFunds = airlines[msg.sender].funded;
        airlines[msg.sender].funded = currentFunds.add(msg.value);
    }

    function isAirline (
                            address airline
                        )
                        external
                        view
                        returns (bool) {
        if (airlines[airline].airlineWallet == airline) {
            return true;
        } else {
            return false;
        }
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        internal
                        pure
                        returns(bytes32)
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function()
                            external
                            payable
    {
        fund();
    }


}

