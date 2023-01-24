var db = {
    'recipients': [],
    'message': [],
    'message_svg': '',
    'message_abi': '',
    'spinners': {},
    'min_price': 10000000000000000,
    'CONTRACT': {
      'abi': undefined,
      'bytecode': undefined,
      'address': '0x0217a10f9508939680fd0E1288d66Dc581021319',
      'address_rinkeby': '0x05b4895762a96DD215c30A2E7b516aAb0011c211',
      'hoot': undefined, // the contract object dynamically set.
    },
    'SETTINGS': {
      'max_len': 240,
      'pad_lines': 12,
    },
    'STATE': {
      'network': {
        'account': undefined,
        'networkId': undefined,
        'checkConnected': (() => { return typeof(getState().network.account)==='undefined' ? false : true }),
        'blockNum': undefined,
        'baseFee': undefined,
        'maxPriorityFee': undefined,
        'gasLimit': undefined,
      }, 
    },
  }
  function getQueryStringDict() {
    var paramDict = {}
    if(window.location.search.length>1) {
      window.location.search.slice(1).split("&").forEach((kv) => { 
        [k,v] = kv.split('=');
        if(k in paramDict) {
          if(Array.isArray(paramDict[k])) {
            paramDict[k].push(v);
          }
        }
        paramDict[k]=v;
      });
    }
    return paramDict;
  }
  function throwAlert(message) {
    alert(message);
  }
  function updateLoginStatus() {
    var acct = db.STATE.network.account;
    var elLogin = document.getElementById('login');
    var elLoginParent = document.getElementById('login').parentElement;
    elLoginParent.removeChild(elLogin);
  
    var banner = 'Connected (' + acct.slice(0, 6) + '...' + acct.slice(
      acct.length-6, acct.length) + ')';
    elLogin = document.createElement('div');
    elLogin.id = 'login';
    elLogin.appendChild(document.createTextNode(banner));
    elLoginParent.appendChild(elLogin);
  
    refreshMyHoots();
  }
  function loadOneHoot(tokenId, callback) {
    getContract().hoot.methods.tokenURI(tokenId).call((err, res) => {
      if (!err) {
        var clipIdx = "data:application/json;base64,".length;
        const jsonUri = atob(res.substring(clipIdx));
        const json = JSON.parse(jsonUri);
        if(callback) {
          callback(json);
        }
      }
    });
  }
  const getHoots = async(callback) => {
    const numHoots = await getContract().hoot.methods.balanceOf(db.STATE.network.account)
      .call({ from: getState().network.account });
    for(var i=0; i<numHoots; i++) {
      getContract().hoot.methods.tokenOfOwnerByIndex(account,i)
        .call({ from: getState().network.account }, (error,result) => {
          if (!error) {
            loadOneHoot(result, callback);
          }
        });
    }
  }
  function getContract() { return db['CONTRACT'] }
  function loadContractAbiAndBytecode() {
    fetch('contracts/nftmsg.json')
      .then(response => response.json())
      .then(data => {
        const bytecode = data['bytecode'];
        const abi = data['abi'];
        getContract().bytecode = bytecode;
        getContract().abi = abi;
      })
      .catch(() => {
        throwAlert("Unable to load smart contract information; the app won't work without it.");
      });
  }
  function getState() {
    return db['STATE'];
  }
  function getMessageAsLinesArray() {
    var lines = db['message'].split('\n');
    var goodlines = [];
    // remove trailing linebreaks
    lines.reverse().forEach((item,i) => { 
      if(item.trim().length != 0) { 
        goodlines = lines.splice(i);
      }
    });
    return goodlines.reverse();
  }
  function saveMessageAsAbiEncoded() {
    var lines = getMessageAsLinesArray();
    var types = null;
  
    /* pad out to db.settings.pad_lines # lines so contract doesn't need a loop */
    lines = lines.concat(Array(db['SETTINGS'].pad_lines - lines.length).fill(''));
    types = Array(db['SETTINGS'].pad_lines).fill("string");
    window.lines = lines;
  
    if (getState().network.checkConnected()) {
      db['message_abi'] = window.web3.eth.abi.encodeParameter('tuple(string[12])', [lines]);
    } else {
      console.log('error web3 not connected; failed to abi.encode...');
    }
  }
  function spin(id, chars) {
    var elSpinner = document.getElementById(id);
    var curIndex = parseInt(elSpinner.getAttribute('data-spindex'));
    curIndex = curIndex + 1;
    if (curIndex >= chars.length) curIndex = 0;
    elSpinner.setAttribute('data-spindex', curIndex);
    elSpinner.innerText = chars[curIndex];
  }
  function startSpinner(el) {
    var spinnerId = Math.floor(Math.random()*1000);
    var spinChars = '|/-\\';
    var spinner = document.createElement('span');
    spinner.setAttribute('id', spinnerId);
    spinner.setAttribute('class', 'spinner');
    spinner.setAttribute('data-spindex', 0);
    el.appendChild(spinner);
    db.spinners[spinnerId] = window.setInterval(spin, 1000, spinnerId, spinChars);
    return spinnerId;
  }
  function stophideSpinner(id) {
    var elSpinner = document.getElementById(id);
    window.clearInterval(db.spinners[id]);
    delete(db.spinners[id]);
    elSpinner.parentNode.removeChild(elSpinner);
  }
  function clearMintMessages() {
    var elMintStatus = document.getElementById('mint-status');
    var newMintStatus= document.createElement('div');
    newMintStatus.id = 'mint-status';
    elMintStatus.parentNode.appendChild(newMintStatus);
    elMintStatus.parentNode.removeChild(elMintStatus);
  }
  function addMintMessage(message, bFailureMessage) {
    var elMintStatus = document.getElementById('mint-status');
    elMintStatus.innerText = elMintStatus.innerText + message;
  }
  function cleanUpMintModal() {
    stophideSpinner(spinnerId);
    window.setTimeout(() => {
      hideModal('modal-mint');
      clearMintMessages();
    }, 3000);
  }
  function startUpMintModal() {
    clearMintMessages();
    showModal('modal-mint');
    spinnerId = startSpinner(document.getElementById('mint-spinner'));
  }
  function processMintPromise(promise) {
    promise.on('sent', (payload) => { 
      addMintMessage('success.\n', false); 
      addMintMessage('Awaiting approval in wallet...', false); 
    })
      .on('transactionHash', (hash) => {
        addMintMessage('success.\n', false); 
        addMintMessage('Awaiting confirmation...', false); 
      })
      .on('receipt', (receipt) => {
        addMintMessage('success!\n', false);
        addMintMessage('\nHoot hoot!', false);
        cleanUpMintModal();
        refreshMyHoots();
      })
      .on('error', (error, receipt) => {
        addMintMessage('FAILED (' + error.code + '): ' + error.message, true);
        cleanUpMintModal();
      });
  }
  function mint() {
    let spinnerId;
    var numConfirmations = 0;
    startUpMintModal();
    saveMessageAsAbiEncoded();
    if(!getState().network.checkConnected()) {
      addMintMessage('Please connect your wallet first!', true);
      cleanUpMintModal();
      return;
    }
    addMintMessage('Preparing transaction...', false);
    if (db.recipients.length===0) {
      getContract().hoot.methods.mint(db.message_abi).estimateGas({
        from: getState().network.account,
        value: db.min_price,
      })
        .then((gas) => {
          var gaslt = Math.floor(parseInt(gas) * 1.005);
          var mintPromise = getContract().hoot.methods.mint(db.message_abi)
            .send({
              from: getState().network.account,
              value: db.min_price,
              gasLimit: gaslt,
            });
          processMintPromise(mintPromise);
        })
        .catch((error) => {
          addMintMessage('FAILED (' + error.code + '): ' + error.message, true);
          cleanUpMintModal();
        });
    } else {
      const mintPrice = db.min_price * db.recipients.length;
      getContract().hoot.methods.mintTo(db.message_abi, db.recipients.length, db.recipients, false).estimateGas({
        from: getState().network.account,
        value: mintPrice,
        // gasLimit: getState().network.gasLimit,
      })
        .then((gas) => {
          var gaslt = Math.floor(parseInt(gas)*1.005);
          var mintPromise = getContract().hoot.methods.mintTo(db.message_abi, db.recipients.length, db.recipients, false)
            .send({
              from: getState().network.account,
              value: mintPrice,
              // gasLimit: gaslt
            });
          processMintPromise(mintPromise);
  
        })
        .catch((error) => {
          addMintMessage('FAILED (' + error.code + '): ' + error.message, true);
          cleanUpMintModal();
        });
    }
  }
  function addRecipiant(to) {
    if(!db.recipients.includes(to)) {
      db.recipients.push(to);
    }
  }
  function removeRecipiant(to) {
    db.recipients = db.recipients.filter(ele => !(ele==to));
  }
  function updateUI() {
    var elHeader = document.getElementById('header');
    var elRecip = document.getElementById('recipients');
    if (elRecip) { elHeader.removeChild(elRecip); }
    elRecip = document.createElement('ul');
    elRecip.id = 'recipients';
    elHeader.appendChild(elRecip);
    db.recipients.forEach(function(r) {
      var newRecip = document.createElement('li');
      newRecip.addEventListener("click", function(event) {
        removeRecipiant(newRecip.innerText);
        updateUI();
      });
      newRecip.innerText = r;
      elRecip.appendChild(newRecip);
    });
  }
  function genOneLineOfText(x, y, style, text) {
    var elOneLine = document.createElementNS("http://www.w3.org/2000/svg", "text"); 
    elOneLine.setAttribute("style", style);
    elOneLine.setAttribute("x", x);
    elOneLine.setAttribute("y", y);
    elOneLine.appendChild(document.createTextNode(text));
    return elOneLine;
  }
  function genTspan(x,y,text) {
    var elOneLine = document.createElementNS("http://www.w3.org/2000/svg", "tspan"); 
    elOneLine.setAttribute("x", x);
    elOneLine.setAttribute("y", y);
    elOneLine.appendChild(document.createTextNode(text));
    return elOneLine;
  }
  function getTextLines(text) {
    return text.split('\n');
  }
  function getTextFromLines(lines) {
    return lines.join('\n');
  }
  
  function textToSVG(text) {
    var lines = getTextLines(text);
    if (lines.length <= 0) return;
  
    var rectStyle = "fill:white;stroke:black;stroke-width:2;opacity:1";
    var textStyle = "white-space:pre;fill:rgb(15,12,29);font:normal 16px Courier, Monospace, serif;"
    var footerInnerRectStyle = "fill:rgb(15, 12, 29);stroke-width:0;opacity:0.0"
    var footerLabelTextStyle ="font:bold 10px Courier, Monospace, serif;fill:rgb(88, 85, 122)";
  
    var svgTemplate = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    svgTemplate.id = 'card';
    svgTemplate.setAttribute('viewBox', '0 0 200 300');
  
    var newElement = document.createElementNS("http://www.w3.org/2000/svg", "rect");
    newElement.setAttribute("x", "2");
    newElement.setAttribute("y", "2");
    newElement.setAttribute("rx", "2");
    newElement.setAttribute("ry", "2");
    newElement.setAttribute("width", "196");
    newElement.setAttribute("height", "296");
    newElement.setAttribute("style", rectStyle);
    svgTemplate.appendChild(newElement);
  
    var startX = 7;
    var startY = 17;
    newElement = document.createElementNS("http://www.w3.org/2000/svg", "text"); 
    newElement.setAttribute("style", textStyle);
    newElement.setAttribute("x", startX);
    newElement.setAttribute("y", startY);
    newElement.appendChild(document.createTextNode(lines[0]));
    lines.slice(1,lines.length-1).forEach(function(line) {
      startY += 20;
      var tspan = document.createElementNS("http://www.w3.org/2000/svg", "tspan");
      tspan.setAttribute("x", startX);
      tspan.setAttribute("y", startY);
      tspan.appendChild(document.createTextNode(line));
      newElement.appendChild(tspan);
    });
    svgTemplate.appendChild(newElement);
  
    newElement = document.createElementNS("http://www.w3.org/2000/svg", "rect");
    newElement.setAttribute("x", "3");
    newElement.setAttribute("y", "245");
    newElement.setAttribute("rx", "0");
    newElement.setAttribute("ry", "0");
    newElement.setAttribute("width", "194");
    newElement.setAttribute("height", "52");
    newElement.setAttribute("style", footerInnerRectStyle);
    svgTemplate.appendChild(newElement);
  
    var elFoot = svgTemplate.appendChild(genOneLineOfText(7, 278, footerLabelTextStyle, "hoots.xyz"));
    elFoot.appendChild(genTspan(171,257,",_,"));
    elFoot.appendChild(genTspan(164,269,"(o,o)"));
    elFoot.appendChild(genTspan(164,281,"{`\"'}"));
    elFoot.appendChild(genTspan(164,293,"-\"-\"-"));
    svgTemplate.appendChild(elFoot);
  
    return svgTemplate;
  }
  function initTo() {
    function addVerifiedRecip(address, spinnerIdx) {
      addRecipiant(address);
      stophideSpinner(spinnerIdx);
      elTo.value = ''
      updateUI();
      elTo.focus();
    }
    var elTo = document.getElementById('to');
    elTo.addEventListener("keypress", function(event) {
      if (event.keyCode == 13) {
        var address = elTo.value;
        var idx = startSpinner(elTo.parentNode);
        if(address.includes('.eth')) {
          try {
          window.web3.eth.ens.getAddress(address)
            .then((addr) => {
              address = addr;
              addVerifiedRecip(address, idx);
            })
            .catch((err) => {
              alert('Unable to resolve ENS name; please use standard 0x... address instead');
              stophideSpinner(idx);
            });
          } catch {
              alert('Unable to resolve ENS name; please use standard 0x... address instead');
              stophideSpinner(idx);
          }
        } else {
          addVerifiedRecip(address, idx);
        }
      }
    });
    let qstr = new URLSearchParams(window.location.search);
    let recips = qstr.getAll('to');
    recips.forEach((recip,i) => {
      addRecipiant(recip);
    });
  }
  function updateSVG(elPreviewSVG) {
    elPreviewSVG.innerHTML = '';
    elPreviewSVG.appendChild(db.message_svg);
  }
  function cleanMessageAndUpdateCounter(elEditor) {
    if (elEditor.innerText.length > db['SETTINGS'].max_len) {
      elEditor.innerText = elEditor.innerText.slice(0, db['SETTINGS'].max_len);
    }
    var lines = getTextLines(elEditor.innerText);
    if (lines.length > db['SETTINGS'].pad_lines+1) {
      lines = lines.slice(0,db['SETTINGS'].pad_lines);
      elEditor.innerText = getTextFromLines(lines);
    }
    var elCounter = document.getElementById("counter");
    if (elCounter===null) {
      elCounter = document.createElement('span');
      elCounter.setAttribute('id', 'counter');
      elCounter.setAttribute('class', 'counter');
      elEditor.parentNode.appendChild(elCounter);
    }
    elCounter.innerText = elEditor.innerText.length + '/' + db['SETTINGS'].max_len;
  }
  function initContentEditor() {
    function getMsgAsSVG_andSave(elEditor) {
      db.message = elEditor.innerText;
      db.message_svg = textToSVG(db.message);
    }
    var elEditor = document.getElementById('message');
    var elPreviewSVG = document.getElementById('preview');
    elEditor.addEventListener("input", function(event) {
      cleanMessageAndUpdateCounter(elEditor);
      getMsgAsSVG_andSave(elEditor);
      updateSVG(elPreviewSVG);
    });
    elEditor.addEventListener('paste', (event) => {
      event.preventDefault();
      document.execCommand('inserttext', false, event.clipboardData.getData('text/plain'));
    });
    cleanMessageAndUpdateCounter(elEditor);
    getMsgAsSVG_andSave(elEditor);
    updateSVG(elPreviewSVG);
  }
  function toggleMyHootsVisible() {
    var elMyHoots = document.getElementById('receivedhoots');
    if (elMyHoots.classList.contains("is-hidden")) {
      elMyHoots.classList.remove("is-hidden");
      elMyHoots.classList.add("is-visible");
    } else {
      elMyHoots.classList.remove("is-visible");
      elMyHoots.classList.add("is-hidden");
    }
  }
  function refreshMyHoots(hoot) {
    clearMyHoots();
    getHoots(updateMyHoots, (hoot) => {
      updateMyHoots(hoot);
    });
  }
  function clearMyHoots() {
    const hoots = document.getElementsByClassName('hoot-thumbnail');
    while(hoots.length > 0) {
      hoots[0].parentNode.removeChild(hoots[0]);
    }
  }
  function updateMyHoots(hoot) {
    var elMyHoots = document.getElementById('receivedhoots');
    var elHoot = document.createElement('img');
    elHoot.setAttribute('class', 'hoot-thumbnail');
    elHoot.setAttribute('src', hoot.image);
    elMyHoots.appendChild(elHoot);
  }
  function showModal(id, content) {
    const elModal = document.getElementById(id);
    const elModalBodymask = document.getElementById("body-mask");
  
    elModal.classList.add('is-visible');
    elModal.classList.remove('is-hidden');
    elModalBodymask.classList.add('is-visible');
    elModalBodymask.classList.remove('is-hidden');
  
    const scrollY = document.documentElement.style.getPropertyValue('--scroll-y');
    const body = document.body;
    body.style.position = 'fixed';
    body.style.top = -scrollY;
  }
  function hideModal(id, content) {
    const elModal = document.getElementById(id);
    const elModalBodymask = document.getElementById("body-mask");
  
    elModal.classList.remove('is-visible');
    elModal.classList.add('is-hidden');
    elModalBodymask.classList.remove('is-visible');
    elModalBodymask.classList.add('is-hidden');
  
    const scrollY = document.body.style.top;
    document.body.style.position = '';
    document.body.style.top = '';
    window.scrollTo(0, parseInt(scrollY || '0') * -1);
  }
  function initModals() {
    const elsModalClose = document.querySelectorAll(".modal-dlg .close");
    const elModalBodymask = document.getElementById("body-mask");
    elsModalClose.forEach((elClose) => {
      elClose.addEventListener('click', () => {
        elClose.parentNode.classList.add('is-hidden');
        elClose.parentNode.classList.remove('is-visible');
        elModalBodymask.classList.remove('is-visible');
        elModalBodymask.classList.add('is-hidden');
      });
    });
  }
  function main() {
    loadContractAbiAndBytecode();
    initModals();
    initTo();
    initContentEditor();
    updateUI();
    document.getElementById("mint").addEventListener("click", function(event) {
      mint();
    });
    document.getElementById('login').addEventListener('click', tryConnecting);
    document.getElementById('owl').addEventListener('click', toggleMyHootsVisible);
    document.querySelectorAll('.contract_link').forEach((item) => {
      item.innerHTML = getContract().address;
    });
  }
  