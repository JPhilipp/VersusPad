var g_persistentData = new Object();

/***************/


Vector.prototype.mag = function() {
    return Math.sqrt(this.x * this.x + this.y * this.y); 
}

Vector.prototype.sub = function(other) {
    this.x -= other.x;
    this.y -= other.y;
}

Vector.prototype.add = function(other) {
    this.x += other.x;
    this.y += other.y;
}

Vector.prototype.mul = function(c) {
    this.x *= c;
    this.y *= c;
}

Vector.prototype.div = function(c) {
    this.mul(1.0 / c);
}

Vector.prototype.normalize = function() {
    var otherVec = new Vector(this.x, this.y);
    otherVec.mag();
    this.div(otherVec);
}

Vector.prototype.getAngle = function() {
    var angle = Math.atan2(this.y, this.x);
    angleDegrees = angle * (180 / Math.PI);
    return angleDegrees;
}

function Vector(x, y) {
    this.x = Misc.isSet(x) ? x : 0;
    this.y = Misc.isSet(y) ? y : 0;
}

/***************/


Rectangle.prototype.rotate = function(boundingWidth, boundingHeight, degrees) {
    for (var d = degrees; d > 0; d -= 90) {
        var widthOld = this.x2 - this.x1;
        var heightOld = this.y2 - this.y1;
        var x1Old = this.x1;
        var y1Old = this.y1;
        var x2Old = this.x2;
        var y2Old = this.y2;

        this.x1 = boundingHeight - y2Old;
        this.y1 = x1Old;
        this.x2 = this.x1 + heightOld;
        this.y2 = this.y1 + widthOld;

        var tempBoundingWidth = boundingWidth;
        boundingWidth = boundingHeight;
        boundingHeight = tempBoundingWidth;
    }
}

Rectangle.prototype.moveByOffset = function(offsetX, offsetY) {
    this.x1 += offsetX;
    this.y1 += offsetY;
    this.x2 += offsetX;
    this.y2 += offsetY;
}

Rectangle.prototype.expand = function(size) {
    this.x1 -= size;
    this.y1 -= size;
    this.x2 += size;
    this.y2 += size;
}

Rectangle.prototype.setToRect = function(rect) {
    this.x1 = rect.x1;
    this.y1 = rect.y1;
    this.x2 = rect.x2;
    this.y2 = rect.y2;
}

Rectangle.prototype.getInfo = function() {
    return this.x1 + ',' + this.y1 + ' to ' + this.x2 + ',' + this.y2;
}

Rectangle.prototype.getWidth = function() {
    return this.x2 - this.x1;
}

Rectangle.prototype.getHeight = function() {
    return this.y2 - this.y1;
}

Rectangle.prototype.subtract = function(padding) {
    this.x1 += padding.left;
    this.y1 += padding.top;
    this.x2 -= padding.right;
    this.y2 -= padding.bottom;
}

Rectangle.prototype.show = function(offsetX, offsetY) {
    if ( !Misc.isSet(offsetX) ) { offsetX = 0; }
    if ( !Misc.isSet(offsetY) ) { offsetY = 0; }

    var elm = document.createElement('div');
    elm.setAttribute('class', 'rectangle');
    elm.style.left = offsetX + this.x1 + 'px';
    elm.style.top = offsetY + this.y1 + 'px';
    elm.style.width = this.x2 - this.x1 + 'px';
    elm.style.height = this.y2 - this.y1 + 'px';
    document.body.appendChild(elm);
}

function Rectangle(x1, y1, x2, y2) {
    this.x1 = x1;
    this.y1 = y1;
    this.x2 = x2;
    this.y2 = y2;
}

/***************/


function Padding(left, top, right, bottom) {
    this.left = Misc.isSet(left) ? left : 0;
    this.top = Misc.isSet(top) ? top : 0;
    this.right = Misc.isSet(right) ? right : 0;
    this.bottom = Misc.isSet(bottom) ? bottom : 0;
}

/***************/


Line.prototype.show = function() {
    var rect = new Rectangle(this.x1, this.y1, this.x2, this.y2);
    rect.show();
}

function Line(x1, y1, x2, y2) {
    this.x1 = x1;
    this.y1 = y1;
    this.x2 = x2;
    this.y2 = y2;
}

/***************/


function ByRefObject(value) {
    this.value = value;
}

/***************/


Position.prototype.getDistanceTo = function(otherPos) {
    return Misc.getDistance(this.x, this.y, otherPos.x, otherPos.y);
}

function Position(x, y) {
    this.x = Misc.isSet(x) ? x : null;
    this.y = Misc.isSet(y) ? y : null;
}

/***************/


function Size(width, height) {
    this.width = width;
    this.height = height;
}

/***************/


Array.prototype.toUnique = function() {
    var r = new Array();
    o:for (var i = 0, n = this.length; i < n; i++) {
        for (var x = 0, y = r.length; x < y; x++) {
            if (r[x] == this[i] || r[x] + ' ' == this[i] + ' ') {
                continue o;
            }
        }
        r[r.length] = this[i];
    }
    return r;
}

Array.prototype.inArray = function(v) {
    var isIt = false;
    for (var i = 0; i < this.length; i++) {
        if (this[i] == v) {
            isIt = true;
            break;
        }
    }
    return isIt;
}

/***************/


String.prototype.ucFirst = function() {
    var f = this.charAt(0).toUpperCase();
    return f + this.substr(1, this.length - 1);
}

String.prototype.toXml = function() {
    return Misc.toXml(this);
}

String.prototype.toName = function(allowUpperCase) {
    return Misc.toName(this, allowUpperCase);
}

String.prototype.toAttribute = function() {
    return Misc.toAttribute(this);
}

String.prototype.trim = function() {
    var s = this;
    if (s) {
        s = s.replace(new RegExp("^[ ]+", "g"), "");
        s = s.replace(new RegExp("[ ]+$", "g"), "");
    }
    return s;
}

String.prototype.cutLength = function(maxLength) {
    if (!maxLength) { maxLength = 20; }
    var value = this;
    var ender = '...';
    if (this.length - ender.length > maxLength) {
        value = this.substr(0, maxLength - ender.length) + ender;
    }
    return value;
}

String.prototype.cutLengthAbrupt = function(maxLength) {
    if (!maxLength) { maxLength = 20; }
    var value = this;
    if (this.length > maxLength) {
        value = this.substr(0, maxLength);
    }
    return value;
}

String.prototype.ucWords = function() {
    if (this) {
        var str = this;
        return (str+'').replace(/^(.)|\s(.)/g, function ( $1 ) { return $1.toUpperCase( ); } );
    }
}

String.prototype.getTextBetween = function(sFrom, sTo) {
    var sPart = '';
    var iFrom = this.indexOf(sFrom);
    var iTo = this.indexOf(sTo, iFrom);
    iFrom += sFrom.length;
    if (iTo > iFrom) { sPart = this.substring(iFrom, iTo); }
    return sPart;
}

String.prototype.replaceAll = function(sFind, sReplace) {
    var s = this;
    var sOld = null;
    while (sOld != s) {
        sOld = s;
        s = s.replace(sFind, sReplace);
    }
    return s;
}

/***************/


function Misc() {
}

/* Misc.cutFloat = function(n) {
    return parseInt(n * 100) / 100;
} */

Misc.getPercent = function(all, part) {
    var p = null;
    if (all < part) {
        p = 100;
    }
    else {
        p = (part / all) * 100;
    }
    return p;
}

Misc.setImageSource = function(id, src) {
    var elm = document.getElementById(id);
    elm.src = src;
}

Misc.getElm = function(id) {
    return document.getElementById(id);
}

Misc.getCreateElement = function(id) {
    var elm = document.getElementById(id);
    if (!elm) {
        elm = document.createElement('div');
        elm.setAttribute('id', id);
        document.body.appendChild(elm);
    }
    return elm;
}

Misc.toggleElm = function(id) {
    var elm = document.getElementById(id);
    if (elm) {
        if (elm.style.display == 'block') {
            elm.style.display = 'none';
        }
        else {
            elm.style.display = 'block';
        }
    }
}

Misc.elmExists = function(id) {
    var elm = document.getElementById(id);
    return Misc.isSet(elm);
}

Misc.isShowing = function(id) {
    var isShowing = false;
    var elm = document.getElementById(id);
    if (elm) { isShowing = elm.style.display == 'block'; }
    return isShowing;
}

Misc.showElm = function(id) {
    var elm = document.getElementById(id);
    if (elm) { elm.style.display = 'block'; }
}

Misc.hideElm = function(id) {
    var elm = document.getElementById(id);
    if (elm) { elm.style.display = 'none'; }
}

Misc.getHtml = function(id) {
    var html;
    var elm = document.getElementById(id);
    if (elm) {
        html = elm.innerHTML;
    }
    else {
        // alert('Element ' + id + ' not found.');
    }
    return html;
}

Misc.setHtml = function(id, html) {
    var elm = document.getElementById(id);
    if (elm) {
        elm.innerHTML = html;
    }
    else {
        // alert('Element ' + id + ' not found.');
    }
}

Misc.getRandomString = function(stringLength) {
    var chars = '0123456789abcdefghiklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if ( !Misc.isSet(stringLength) ) { stringLength = 64; }
    var randomString = '';
    for (var i=0; i < stringLength; ++i) {
        var rnum = Math.floor( Math.random() * chars.length );
        randomString += chars.substring(rnum, rnum + 1);
    }
    return randomString;
}

Misc.toXml = function(s) {
    if (s || s == 0) {
        s = s.toString();
        s = s.replace(/&/g, '&amp;');
        s = s.replace(/</g, '&lt;');
        s = s.replace(/>/g, '&gt;');
    }
    else {
        s = '';
    }
    return s;
}

Misc.toAttribute = function(s) {
    if (s) {
        s = s.toString();
        s = Misc.toXml(s);
        s = s.replace(/"/g, '&quot;');
        // ... s = s.replace(/'/g, '&#145;');
    }
    else {
        s = '';
    }
    return s;
}

Misc.toName = function(s, allowUpperCase) {
    var name = '';
    if (!allowUpperCase) { s = s.toLowerCase(); }
    var allowed = [
            'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',
            '0','1','2','3','4','5','6','7','8','9', '_'];
    if (allowUpperCase) {
        var max = allowed.length;
        for (var i = 0; i < max; ++i) {
            var allowedUpper = allowed[i].toUpperCase();
            if (allowedUpper != allowed[i]) {
                allowed[allowed.length] = allowedUpper;
            }
        }
    }
    for (var i = 0; i < s.length; ++i) {
        var letter = s.substring(i, i + 1);
        if ( allowed.inArray(letter) ) { name += letter; }
    }
    return name;
}

Misc.getChars = function(thisChar, numberOfChars) {
    var s = '';
    for (var i = 1; i <= numberOfChars; i++) {
        s += thisChar;
    }
    return s;
}

Misc.forceMin = function(v, min) {
    if (min != null && v < min) { v = min; }
    return v;
}

Misc.forceMinMax = function(v, min, max) {
    if (min != null && v < min) {
        v = min;
    }
    else if (max != null && v > max) {
        v = max;
    }
    return v;
}

Misc.getRandomInt = function(min, max) {
    if ( !Misc.isSet(max) ) {
        max = min;
        min = 0;
    }
    return parseInt( Math.floor( ( (max + 1 - min) * Math.random() ) + min ) );
}

Misc.getRandom = function(min, max) {
    return ( (max + 1 - min) * Math.random() ) + min;
}

Misc.getFormValue = function(id) {
    var v = '';
    var elm = document.getElementById(id);
    if (elm) { v = Misc.getElmFormValue(elm); }
    return v;
}

Misc.getElmFormValue = function(elm) {
    var v = '';
    switch (elm.type) {
        case 'checkbox':
            v = elm.checked;
            break;
        default:
            v = elm.value;
    }
    return v;
}

Misc.setFormValue = function(id, v) {
    var elm = document.getElementById(id);
    if (elm) {
        elm.value = v;
    }
}

Misc.preloadImage = function(url) {
    var img =  new Image();
    img.src = url;
}

Misc.pad = function(v) {
    if ( (v+'').length == 1) { v = '0' + v; }
    return v;
}

Misc.focusElm = function(id) {
    var elm = document.getElementById(id);
    if (elm) { elm.focus(); }
}

Misc.setOpacity = function(elm, opacityFloat) {
    elm.style.MozOpacity = opacityFloat;
    elm.style.opacity = opacityFloat;
}

Misc.elmExists = function(id) {
    return !!document.getElementById(id);
}

Misc.escapeRegex = function(s) {
    return s.replace(/([\\\^\$>*+[\]?{}.=!:(|)])/g, '\\$1');
}

Misc.doReplace = function(sAll, sFind, sReplace, caseSensitive) {
    sFind = Misc.escapeRegex(sFind);
    var regexFind = new RegExp( sFind, (caseSensitive ? 'g' : 'gi') );
    return sAll.replace(regexFind, sReplace);
}

Misc.ucWords = function(s) {
    return (typeof s == 'string') ? s.ucWords() : null;
}

Misc.getParam = function(id) {
    var thisValue = null;
    var hash = parent.location.hash;
    if (hash != '') {
        var params = hash.substring(1);
        if ( params.indexOf('=') >= 0) {
            var nameValues = params.split('&');
            for (var i = 0; i < nameValues.length; ++i) {
                var nameValue = nameValues[i].split('=');
                if (id == nameValue[0]) {
                    thisValue = nameValue[1];
                    break;
                }
            }
        }
    }
    return thisValue;
}

Misc.getChance = function(chanceOfSuccessInPercent) {
    var ok = false;
    if (chanceOfSuccessInPercent > 0) {
        ok = Misc.getRandom(0, 100) <= chanceOfSuccessInPercent;
    }
    return ok;
}

Misc.positionElm = function(id, x, y) {
    var elm = document.getElementById(id);
    if (x != null) { elm.style.left = x + 'px'; }
    if (y != null) { elm.style.top = y + 'px'; }
}

Misc.isSet = function(v) {
    return v != null && !(v === undefined);
}

Misc.createString = function(length, thisChar) {
    var s = '';
    for (var i = 1; i <= length; i++) {
        s += thisChar;
    }
    return s;
}

Misc.verboseBool = function(v) {
    return v ? 'true' : 'false';
}

Misc.formatNumber = function(nStr) {
    nStr += '';
    x = nStr.split('.');
    x1 = x[0];
    x2 = x.length > 1 ? '.' + x[1] : '';
    var rgx = /(\d+)(\d{3})/;
    while (rgx.test(x1)) {
        x1 = x1.replace(rgx, '$1' + ',' + '$2');
    }
    return x1 + x2;
}

Misc.getDistance = function(x1, y1, x2, y2) {
    var distanceX = x1 - x2;
    var distanceY = y1 - y2;
    return Math.sqrt(distanceX * distanceX + distanceY * distanceY);
}

Misc.getArrayClone = function(arr) {
    var arrClone = new Array();
    for (var i = 0; i < arr.length; i++) { arrClone[i] = arr[i]; }
    return arrClone;
}

Misc.getObjectInfoAsHtml = function(obj, optionalShowAllValues) {
    var s = Misc.getObjectInfoAsText(obj, optionalShowAllValues);
    s = s.toXml();
    s = s.replace("\r", '<br/>');
    return s;
}

Misc.getObjectInfoAsText = function(obj, optionalShowAllValues) {
    var keyValues = new Array();
    for (var key in obj) {
        var typeOfThis = typeof(obj[key]);
        if (typeOfThis == 'object') {
            /*
            var isOk = true;
            var v = obj[key];
            if (v.length) {
                if ( Misc.isSet(optionalShowAllValues) && optionalShowAllValues == false ) {
                    isOk = v.length >= 1;
                }
                if (isOk) { keyValues[keyValues.length] = 'array of length ' + v.length + ': ' + v.join(';'); }
            }
            */
        }
        else if (typeOfThis != 'function') {
            var isOk = true;
            var v = obj[key];
            if ( Misc.isSet(optionalShowAllValues) && optionalShowAllValues == false ) {
                isOk = v != 0 && v != '' && v != null && v != false;
            }
            if (isOk) { keyValues[keyValues.length] = key + ': ' + v; }
        }
    }
    return keyValues.join("\r");
}

Misc.shuffleArray = function(arr) {
    arr.sort( function() {return 0.5 - Math.random()} );
}

Misc.roundNumber = function(num, decimalPlaces) {
    if ( !Misc.isSet(decimalPlaces) ) { decimalPlaces = 1; }
    return Math.round( num * Math.pow(10, decimalPlaces) ) / Math.pow(10, decimalPlaces);
}

Misc.addAsFirstEntryIfUnique = function(arr, v, maxEntries) {
    var newArr = new Array();
    if ( !arr.inArray(v) ) {
        newArr[newArr.length] = v;
        for (var i = 0; i < arr.length && i < maxEntries - 1; i++) {
            newArr[newArr.length] = arr[i];
        }
        arr = newArr;
    }
    return newArr;
}

Misc.removeLastFromArray = function(arr) {
    var newArr = arr.splice(arr.length - 1, 1);
    return newArr;
}

Misc.createElmById = function(id) {
    var elm = document.createElement('div');
    elm.setAttribute('id', id);
    document.body.appendChild(elm);
    return elm; // does the return work?
}

Misc.removeElmById = function(id) {
    var elm = document.getElementById(id);
    if (elm) { document.body.removeChild(elm); }
}

Misc.createTestPoint = function(pos) {
    var elm = document.createElement('div');
    elm.setAttribute('class', 'testPoint');
    elm.style.left = pos.x - 2 + 'px';
    elm.style.top = pos.y - 2 + 'px';
    document.body.appendChild(elm);
}

Misc.toArray = function(v) {
    if ( Misc.isSet(v) && Misc.typeOf(v) != 'array' ) {
        var vArr = new Array();
        vArr[0] = v;
        v = vArr;
    }    
    return v;
}

Misc.typeOf = function(value) {
    var s = typeof value;
    if (s === 'object') {
        if (value) {
            if ( typeof value.length === 'number' &&
                    !( value.propertyIsEnumerable('length') ) &&
                    typeof value.splice === 'function' ) {
                s = 'array';
            }
        } else {
            s = 'null';
        }
    }
    return s;
}


/*** NewsDialog object; requires global app object ***/

NewsDialog.prototype.handle = function() {
    var delayMs = Misc.isSet(app.isLocalTest) && app.isLocalTest ? 1500 : 4000;
    setTimeout(g_newsDialog_checkNews, delayMs);
}

NewsDialog.prototype.checkNews = function() {
    var today = this.getIsoDate();
    var lastTriedToShowDate = localStorage.getItem('dialog_lastTriedToShowDate');
    var waitBeforeTryShowingDays = localStorage.getItem('dialog_waitBeforeTryShowingDays');

    if ( !Misc.isSet(lastTriedToShowDate) ) {
        localStorage.setItem('dialog_lastTriedToShowDate', today);
        localStorage.setItem( 'dialog_waitBeforeTryShowingDays', Misc.getRandomInt(2, 4) );
    }
    else {

        /* app.debug( 'lastTriedToShowDate = ' + lastTriedToShowDate + '<br/>' +
                'waitBeforeTryShowingDays = ' + waitBeforeTryShowingDays + '<br/>' +
                'today = ' + today + '<br/>' +
                'difference days = ' + this.getDifferenceBetweenDatesInDays(lastTriedToShowDate, today) );
        */

        var differenceInDays = this.getDifferenceBetweenDatesInDays(lastTriedToShowDate, today);
        if ( parseInt(differenceInDays) >= parseInt(waitBeforeTryShowingDays) ) {
            localStorage.setItem('dialog_lastTriedToShowDate', today);
            localStorage.setItem( 'dialog_waitBeforeTryShowingDays', Misc.getRandomInt(1, 2) );

            // app.debugAndStop('Contacting server...');
            if ( Misc.isSet(app.isLocalTest) && app.isLocalTest ) {
                var testResponse = "citybucks61;citybucks,roswellgame;;Test you" +
                        ";itms://itunes.apple.com/us/app/ogs/id384664859;4-7";
                // testResponse = '4-7';
                this.handleNewsResponse(testResponse);
            }
            else {
                var newsUrl = 'http://file.versuspad.com/news.txt';
                newsUrl += '?guid=id' + Misc.getRandomString(32);
                g_persistentData['ajaxRequestNewsDialog'] = new XMLHttpRequest();
                g_persistentData['ajaxRequestNewsDialog'].onreadystatechange = g_newsDialog_checkNewsResponse;
                g_persistentData['ajaxRequestNewsDialog'].open('GET', newsUrl, true);
                g_persistentData['ajaxRequestNewsDialog'].send(null);
            }

        }
    }
}

NewsDialog.prototype.checkNewsResponse = function() {
    var didReceive = g_persistentData['ajaxRequestNewsDialog'].readyState == 4 && g_persistentData['ajaxRequestNewsDialog'].status == 200;
    if (didReceive) {
        this.handleNewsResponse(g_persistentData['ajaxRequestNewsDialog'].responseText);
    }
}

NewsDialog.prototype.handleNewsResponse = function(responseText) {
    var responseDataArr = responseText.split(';');
    var requiredLength = 6;
    if (responseDataArr.length == requiredLength) {
        var i = 0;
        var guid = responseDataArr[i++];
        var recipientsString = responseDataArr[i++];
        var recipientsExcludedString = responseDataArr[i++];
        var text = responseDataArr[i++];
        var url = responseDataArr[i++];
        var waitBeforeTryShowingDays = this.getValueFromRangeString(responseDataArr[i++]);

        var recipients = recipientsString != '' ? recipientsString.split(',') : new Array();
        var recipientsExcluded = recipientsExcludedString != '' ? recipientsExcludedString.split(',') : new Array();

        localStorage.setItem('dialog_waitBeforeTryShowingDays', waitBeforeTryShowingDays);
        var isRecipient = ( recipients.inArray(app.name) || recipients.inArray(app.name + ' ' + app.version) ) &&
                !( recipientsExcluded.inArray(app.name) || recipientsExcluded.inArray(app.name + ' ' + app.version) )
        if ( isRecipient && !this.newsIsBlacklisted(guid) ) {
            this.waitBeforeTryShowingDays = waitBeforeTryShowingDays;
            localStorage.setItem( 'dialog_waitBeforeTryShowingDays', Misc.getRandomInt(1, 2) );
            this.show(guid, text, url);
        }
    }
    else {
        var waitBeforeTryShowingDays = responseText != '' ? this.getValueFromRangeString(responseText) : 1;
        localStorage.setItem('dialog_waitBeforeTryShowingDays', waitBeforeTryShowingDays);
    }
}

NewsDialog.prototype.getValueFromRangeString = function(rangeString) {
    var v = null;
    var fromToArr = rangeString.split('-');
    if (fromToArr.length == 2) {
        v = Misc.getRandomInt( parseInt(fromToArr[0]), parseInt(fromToArr[1]) );
    }
    else {
        v = parseInt(rangeString);
    }
    return v;
}

NewsDialog.prototype.show = function(guid, text, url) {
    var s = '';
    if (!app.gameRuns == false) { app.togglePause(false); }

    s += '<div class="dialogMessage">';
    s += "    <a href=\"javascript:g_newsDialog_approveAndGoTo('" + url.toXml() + "','" + guid.toXml() + "')\">" + text.toXml() + "</a>";
    s += '</div>';
    s += '<div class="dialogActions">';
    s += '    <a href="javascript:g_newsDialog_remind()" class="dialogRemind">Remind me later</a> ';
    s += "    <a href=\"javascript:g_newsDialog_cancel('" + guid.toXml() + "')\" class=\"dialogCancel\">No thanks</a> ";
    s += "    <a href=\"javascript:g_newsDialog_approveAndGoTo('" + url.toXml() + "','" + guid.toXml() + "')\" class=\"dialogApprove\">Show me!</a>";
    s += '</div>';

    var elm = document.createElement('div');
    elm.setAttribute('id', 'dialog');
    elm.innerHTML = s;
    document.body.appendChild(elm);
}

NewsDialog.prototype.remind = function() {
    localStorage.setItem('dialog_waitBeforeTryShowingDays', 1);
    app.removeElmById('dialog');
    app.togglePause();
}

NewsDialog.prototype.cancel = function(guid) {
    localStorage.setItem('dialog_waitBeforeTryShowingDays', this.waitBeforeTryShowingDays);
    this.addToNewsBlacklist(guid);
    app.removeElmById('dialog');
    app.togglePause();
}

NewsDialog.prototype.approveAndGoTo = function(url, guid) {
    // app.debugAndStop('Setting approveAndGoTo waitBeforeTryShowingDays to ' + this.waitBeforeTryShowingDays);
    localStorage.setItem('dialog_waitBeforeTryShowingDays', this.waitBeforeTryShowingDays);
    app.removeElmById('dialog');
    this.addToNewsBlacklist(guid);
    this.url = url;
    var delayToAllowWriting = 500;
    setTimeout(g_newsDialog_goToUrl, delayToAllowWriting);
}

NewsDialog.prototype.goToUrl = function() {
    window.location.href = this.url;
}

NewsDialog.prototype.addToNewsBlacklist = function(guid) {
    var splitter = '~';
    var daysToRemember = 300;
    var blacklistString = localStorage.getItem('newsBlacklist');
    var blacklist = new Array();
    if ( Misc.isSet(blacklistString) ) { blacklist = blacklistString.split(splitter); }
    if ( !blacklist.inArray(guid) ) {
        blacklist[blacklist.length] = guid.toName();
    }
    localStorage.setItem( 'newsBlacklist', blacklist.join(splitter), daysToRemember );
}

NewsDialog.prototype.newsIsBlacklisted = function(guid) {
    var splitter = '~';
    var blacklistString = localStorage.getItem('newsBlacklist');
    var blacklist = new Array();
    if ( Misc.isSet(blacklistString) ) { blacklist = blacklistString.split(splitter); }
    return blacklist.inArray(guid);
}

NewsDialog.prototype.getIsoDate = function() {
    var now = new Date();
    return now.getFullYear() + '-' + Misc.pad( now.getMonth() + 1 ) + '-' + Misc.pad( now.getDate() );
    // return '2010-08-26';
}

NewsDialog.prototype.getDifferenceBetweenDatesInDays = function(isoDate1, isoDate2) {
    var date1 = this.isoDateToDate(isoDate1);
    var date2 = this.isoDateToDate(isoDate2);
    var oneDayInMs = 1000 * 60 * 60 * 24;
    var differenceInMs = Math.abs( date1.getTime() - date2.getTime() );
    var differenceInDays = Math.ceil(differenceInMs / oneDayInMs);
    return differenceInDays;
}

NewsDialog.prototype.isoDateToDate = function(isoDate) {
    var date = null;
    var isoDateArr = isoDate.split('-');
    if (isoDateArr.length == 3) {
        date = new Date( parseInt(isoDateArr[0]), parseInt(isoDateArr[1] * 1 - 1), parseInt(isoDateArr[2] * 1 + 1) );
    }
    return date;
}

function NewsDialog() {
    this.waitBeforeTryShowingDays = null;
    this.url = null;
}

/***************/


Phase.prototype.isValidName = function(name) {
    var isIt = name >= Enum.phaseMin && name <= Enum.phaseMax && name == parseInt(name)
    if (!isIt) { app.debugAndStop('Tried to set invalid phase name ' + name); }
    return isIt;
}

Phase.prototype.setCounterForNext = function(counter, nextName) {
    if ( this.isValidName(nextName) && counter > 0 ) {
        this.counter = parseInt(counter / app.speedFactor);
        this.nameNext = parseInt(nextName);
    }
}

Phase.prototype.getInitedAndInit = function() {
    var wasInited = this.inited;
    if (!this.inited) {
        this.inited = true;
        // app.debug( 'Now initing phase "' + this.getVerbose() + '"' );
    }
    return wasInited;
}

Phase.prototype.getInfo = function() {
    var defaultCount = 100;
    var s = 'Phase: ' + this.getVerboseByName(this.name);
    if (this.counter != defaultCount && this.counter != null) { s += ' ( ' + this.counter + ')'; }
    if (this.nameNext) { s += '<br />' + 'Next phase: ' + this.getVerboseByName(this.nameNext); }
    return s;
}

Phase.prototype.getVerbose = function() {
    return this.getVerboseByName(this.name);
}

Phase.prototype.getNextVerbose = function() {
    return this.getVerboseByName(this.nameNext);
}

Phase.prototype.getVerboseByName = function(name) {
    return Misc.isSet(app.spriteName[name]) ? app.spriteName[name] : 'Unknown (' + name + ')';
}

Phase.prototype.handleCounter = function() {
    if (this.counter != null && this.nameNext != null) {
        this.counter--;
        if (this.counter <= 0) {
            this.counter = null;
            this.name = parseInt(this.nameNext);
            this.nameNext = null;
            this.inited = false;
        }
        // app.debug('Phase counter: ' + this.counter);
    }
}

function Phase(name) {
    this.name = null;
    if ( Misc.isSet(name) && this.isValidName(name) ) {
        this.name = name;
    }
    this.nameNext = null;
    this.counter = 100;
    this.inited = false;
}
