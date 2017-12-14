

function initiate(contractAddress, contractABI) {

    // Checks Web3 support
    if(typeof web3 !== 'undefined' && typeof Web3 !== 'undefined') {
        // If there's a web3 library loaded, then make your own web3
        web3 = new Web3(web3.currentProvider);
    } else if (typeof Web3 !== 'undefined') {
        // If there isn't then set a provider
        web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
    } else if(typeof web3 == 'undefined') {
        // Alert the user he is not in a web3 compatible browser
        console.log("No valid web3 object");
        return;
    }

    // get contract
    web3.eth.getCode(contractAddress, function(e, r) {
        if (!e && r.length > 3) {
            
            contract = web3.eth.contract(contractABI).at(contractAddress);
            
            loadContract();
        }
    })

    // get accounts
    web3.eth.getAccounts(function(e, r){
        
        accounts = r;

        loadAccounts()
    });
}


function loadContract() {
    var GPSPositionEvent = contract.GPSPosition({}, {fromBlock: 1243767, toBlock: 'latest'});
    GPSPositionEvent.watch(handleLiveGPSEvents);
}


function loadAccounts() {
    for (var i = 1; i <= accounts.length-1; i++) {
        var x = document.getElementById("source-address");
        var option = document.createElement("option");
        option.text = vehicles[i-1] + " (" + accounts[i] + ")";
        option.value = i;
        x.add(option);
    }
}


function handleLiveGPSEvents(e, r) {
    if (!e) { 
        i = vehicle_addresses.indexOf(r.args.from.toUpperCase())
        var timestamp = new Date(r.args.timestamp * 1000);
        msg  = vehicles[i] + ": " + web3.toAscii(r.args.lat) + ", " + web3.toAscii(r.args.lon) + ", " + web3.toAscii(r.args.speed) + ", " + timestamp;
        console.log(r);
        document.getElementById(vehicle_addresses[i]).innerHTML = msg
    } else {
        console.error(e);
    }
}


function getRandomInRange(from, to, fixed) {
    return (Math.random() * (to - from) + from).toFixed(fixed) * 1;
}


function randomizeCoordinates() {
    document.getElementById("lat-input").value = getRandomInRange(-180, 180, 3);
    document.getElementById("long-input").value = getRandomInRange(-180, 180, 3);
    document.getElementById("speed-input").value = getRandomInRange(0, 120, 3);
}


function submitCoordinates() {
 
    lat = web3.fromAscii(document.getElementById("lat-input").value);
    long = web3.fromAscii(document.getElementById("long-input").value);
    speed = web3.fromAscii(document.getElementById("speed-input").value);
    source = accounts[document.getElementById("source-address").value];
    contract.storePosition(lat, long, speed, {from: source}, function(e,r) {console.log(e); console.log(r)})
}

