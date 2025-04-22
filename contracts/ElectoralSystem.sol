// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;
import "./VotersCard.sol";
import "./VoteStamp.sol";

contract ElectoralSystem {

    address public presidingOfficer;
    VotersCard public votersCard;
    
    constructor(){
        presidingOfficer = msg.sender;
        votersCard = new VotersCard(address(this), address(this));
    }

    //#region Electoral Voter Register
    mapping(address => Voter) public electoralRegister;

    struct Voter {
        string name;
        bool registered;        
    }
    
    /*
        Voters can register themselves onto the electotal register
    */
    function registerVoter(string memory _name) public {
        require(!electoralRegister[msg.sender].registered, "Already registered as a voter");
        require(votersCard.balanceOf(msg.sender) == 0, "Voter already issued voters token/card");
        electoralRegister[msg.sender] = Voter(_name, true);
        votersCard.safeMint(msg.sender);
    }
    function isRegistered(address _voter) view  public returns(bool){
        return electoralRegister[_voter].registered && votersCard.balanceOf(_voter) == 1;
    }

    //#endregion

    //#region Candidate management 
    struct Candidate {
        address id;
        string name;
        string party;
        bool nominated;
        bool approved;
    }

    mapping(uint => mapping (address => Candidate)) nominees;  /* year -> Candidate Address*/
    function nominate(uint _year, string memory _name, string memory _party) public {
        require(electionYears[_year], "Election must already be initiated for provided year before nomination can be made");
        require(msg.sender != presidingOfficer, "Presiding officer cannot nominate themselves");
        nominees[_year][msg.sender] = Candidate(msg.sender, _name, _party, true, false);
    }

    /**
        Only presiding officer can approve a candidate for an existing election
    **/
    function approveNomination(uint _year, address _candidate) public {
        require(msg.sender == presidingOfficer, "Nomination can only be approved by presiding officer");
        require(electionYears[_year], "Election must already be initiated for provided year before nomination can be approved");
        require(nominees[_year][_candidate].nominated, "Candidate must already be nominated for provided year before they can be approved");

        Candidate memory candidate = nominees[_year][_candidate];
        candidate.approved = true;
        elections[_year].addCandidate(_candidate, msg.sender);
    }
    function isNominated(address _candidate, uint _year) view  public returns(bool){
        Candidate memory candidate = nominees[_year][_candidate];
        return candidate.nominated;
    }

    //#endregion

    //#region Election management

    mapping(uint => Election) public elections; /* year -> Election Address*/
    mapping(uint => bool) public electionYears; /* year -> bool*/
    mapping(uint => VoteStamp) public voteStamps; /* year -> Election Address*/

   
     /**
        Only presiding officer can initiate an election
        There can only be one election in the same year (how do you deal with re-runs?)
    **/
    function initiateElection(uint _year) public  returns(bool){        
        require(msg.sender == presidingOfficer, "Election can only be created by presiding officer");
        require(!electionYears[_year], "Election is already initiated for provided year");
        elections[_year] = new Election(_year, address(this));
        voteStamps[_year] = new VoteStamp(address(this), address(elections[_year]), _year);
        electionYears[_year] = true;
        return electionYears[_year];
    }
     function isElectionInitiated(uint _year) view  public returns(bool){
        return electionYears[_year];
    }

    function getVoteStamp(uint _year) external view returns(VoteStamp){
        return voteStamps[_year];
    }

    function getElection(uint _year) view  public returns(Election){
        return elections[_year];
    }
    //#endregion

}

contract Election {
    uint public year;
    uint highestVote;
    address public winner;
    address presidingOfficer;
    address esAddress;
    ElectoralSystem es;
    mapping(address => bool) ballot; /* Candidate address to vote tally */
    mapping(address => uint) votingTally; /* Candidate address to vote tally */

    constructor(uint _year, address _electoralSystemAddress) {
        year = _year;
        es = ElectoralSystem(_electoralSystemAddress);
        presidingOfficer = es.presidingOfficer();
        esAddress = _electoralSystemAddress;
    }
    mapping(address => bool) voters;

    function addCandidate(address _candidate, address _requestingOfficer) public {
        require(msg.sender == esAddress, "Candidate nomination can only be approved by presiding officer");
        require(presidingOfficer == _requestingOfficer, "Candidate nomination can only be approved by presiding officer");
        ballot[_candidate] = true;
    }

    function hasVoted(address _voter) view  public returns(bool){
        return voters[_voter] || es.getVoteStamp(year).balanceOf(msg.sender) > 0;
    }
    function vote(address _candidate) public{
        require(es.isRegistered(msg.sender), "User is not registered to vote");
        require(!hasVoted(msg.sender), "Voter has already voted on this year's election");
        require(ballot[_candidate], "Selected candidate is not on the ballot");
        
        voters[msg.sender] = true; 
        es.getVoteStamp(year).safeMint(msg.sender);// Stamp the voter by issuing them a token
        votingTally[_candidate] = votingTally[_candidate] + 1;
        if(votingTally[_candidate] > highestVote){
            highestVote = votingTally[_candidate];
            winner = _candidate;
        }
    }
    
}