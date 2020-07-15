pragma solidity >=0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    address payable public dataContractAddress;
    mapping(address => uint8) private authorizedContracts;

    // airlines info
    struct Airline {
        address airlineWallet;
        bool isRegistered;
        string name;
        uint256 funded;
        address[] votes;
    }
    mapping(address => Airline) private airlines;

    // passengers info
    struct Passenger {
        address passengerWallet;
        mapping(string => uint256) boughtFlight;
        uint256 credit;
    }
    mapping(address => Passenger) private passengers;

    //multiparty variables
    uint8 private constant MULTIPARTY_MIN_AIRLINES = 4;
    uint256 private airlinesCount;

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
    * @dev Modifier that requires the current account to have funded at least 10 eth
    */
    modifier requireMinimumFunded()
    {
        require(airlines[msg.sender].funded >= 10 ether, "You have not funded the minimum of 10 ether");
        _;
    }

    /**
    * @dev Modifier that requires the calling App contract has been authorized
    */
    modifier requireIsCallerAuthorized()
    {
        require(authorizedContracts[msg.sender] == 1, "Caller is not contract owner");
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
                            requireMinimumFunded
                            requireIsCallerAuthorized
                            returns(bool success, uint256 votes)
    {
        require(airlineAddress != address(0), "'airlineAddress' must be a valid address.");
        require(!airlines[airlineAddress].isRegistered, "Airline is already registered.");
        require(!checkIfContains(airlines[airlineAddress].votes), "You already voted to register this airline.");

        if(airlinesCount < MULTIPARTY_MIN_AIRLINES){
            airlines[airlineAddress] = Airline({
                                                airlineWallet: airlineAddress,
                                                isRegistered: true,
                                                name: name,
                                                funded: 0,
                                                votes: new address[](0)
                                        });
            airlines[airlineAddress].votes.push(msg.sender);
            airlinesCount.add(1);
        } else {
            airlines[airlineAddress].votes.push(msg.sender);
            if (airlines[airlineAddress].votes.length >= airlinesCount.div(2)) {
                airlines[airlineAddress].isRegistered = true;
                airlinesCount.add(1);
            }
        }

        return (true, airlines[airlineAddress].votes.length);
    }

    function checkIfContains(address[] memory voters) internal returns(bool alreadyVoted){
        alreadyVoted = false;
        for (uint256 c = 0; c < voters.length; c++) {
            if (voters[c] == msg.sender) {
                alreadyVoted = true;
                break;
            }
        }
        return alreadyVoted;
    }

   /**
    * @dev Buy insurance for a flight
    *
    */
    function buy
                            (
                                string calldata flightCode,
                                uint256 price
                            )
                            external
                            payable
    {
        if (passengers[msg.sender].passengerWallet != msg.sender) {
            passengers[msg.sender] = Passenger({
                                                passengerWallet: msg.sender,
                                                credit: 0
                                        });
            passengers[msg.sender].boughtFlight[flightCode] = price;
        } else {
            passengers[msg.sender].boughtFlight[flightCode] = price;
        }
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                    address passenger,
                                    string calldata flightCode
                                )
                                external
    {
        require(passengers[passenger].boughtFlight[flightCode] != 0, "The passenger does not bought a ticket for this flight");
        uint256 payedPrice = passengers[passenger].boughtFlight[flightCode];
        passengers[passenger].credit = payedPrice + payedPrice.div(2);
    }


    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
    {
        uint256 credit = passengers[msg.sender].credit;
        passengers[msg.sender].credit = 0;
        msg.sender.transfer(credit);
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
    {
        airlines[msg.sender].funded.add(msg.value);
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
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

