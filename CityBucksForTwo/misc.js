/*** Desire object ***/

Desires.prototype.getSum = function() {
    var v = 0;
    for (var key in this) {
        if ( typeof(this[key]) == 'number' ) {
            v += parseInt(this[key]);
        }
    }
    return v;
}

Desires.prototype.getDifference = function(otherDesires) {
    var v = 0;
    for (var key in this) {
        var obj = this[key];
        if ( typeof(this[key]) == 'number' ) {
            v = this[key] - otherDesires[key];
        }
    }
    return v;
}

Desires.prototype.randomize = function() {
    var max = 10;
    for (var key in this) {
        if ( typeof(this[key]) == 'number' ) {
            this[key] = Misc.getRandomInt(0, max);
            alert(this[key]);
        }
    }
}

function Desires() {
    this.food = 0;
    this.drinks = 0;
    this.culture = 0;
    this.money = 0;
    this.sleep = 0;
    this.entertainment = 0;
    this.shopping = 0;
    this.privacy = 0;
    this.company = 0; // dynamically added to for buildings, depending on humans in it
}


/*** Building object ***/

Building.prototype.verifyRequirements = function(requiredOffersSum, buildingName) {
    var offersSum = this.offers.getSum();
    if ( offersSum != parseInt(requiredOffersSum) ) {
        alert( buildingName.ucFirst() + ' has false offers sum ' +
                '(required: ' + requiredOffersSum + ', actual: ' + offersSum + ').' );
    }
}

function Building() {
    this.offers = new Desires();
    this.createsWants = new Desires();
    this.creationCost = 0;
    this.type = null;
    this.wantsAreRandomizedAfterVisit = false;
}

/*** Human object ***/

function Human() {
    this.wants = new Desires();
}


/*** CastButton object ***/

function CastButton() {
    this.guid = 'id' + Misc.getRandomString(16);
    this.x = null;
    this.y = null;
    this.width = 85;
    this.height = 52;
    this.playerI = null;
    this.buttonI = null;
    this.type = null;
    this.elm = null;
    this.elmCross = null;
    this.cost = null;
    this.isClickable = false;
    this.isClickableOld = this.isClickable;
    this.isHighlighted = false;
    this.isHighlightedOld = this.isHighlighted;
}


/*** CastButton ***/

function PlayerAi() {
    this.nextSpriteToCast = null;
}


/*** Rectangle object ***/

function Rectangle(x1, y1, x2, y2) {
    this.x1 = x1;
    this.y1 = y1;
    this.x2 = x2;
    this.y2 = y2;
}


/*** Speed object ***/

function Speed() {
    this.speedX = null;
    this.speedY = null;
}

/*** Coordinate object ***/

function Position(x, y) {
    this.x = Misc.isSet(x) ? x : null;
    this.y = Misc.isSet(y) ? y : null;
}


/*** Size object ***/

function Size(width, height) {
    this.width = width;
    this.height = height;
}


/*** Array object ***/

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


/*** String object ***/

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

/*** Misc object ***/

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
    return parseInt( Math.floor( ( (max + 1 - min) * Math.random() ) + min ) );
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
    return Misc.getRandomInt(0, 100) <= chanceOfSuccessInPercent;
}

Misc.positionElm = function(id, x, y) {
    var elm = document.getElementById(id);
    if (x != null) { elm.style.left = x + 'px'; }
    if (y != null) { elm.style.top = y + 'px'; }
}

Misc.isSet = function(v) {
    return v != null; // undefined === v ? // ...
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


/*** Vector functions ***/

function vec_mag(vec) {
    return Math.sqrt(vec.x * vec.x + vec.y * vec.y); 
}

function vec_sub(a, b) {
    return { x: a.x - b.x, y: a.y - b.y };
}

function vec_add(a, b) {
    return { x: a.x + b.x, y: a.y + b.y };
}

function vec_mul(a, c) {
    return { x: a.x * c, y: a.y * c };
}

function vec_div(a, c) {
    return vec_mul(a, 1.0 / c);
}

function vec_normal(a) {
    return vec_div( a, vec_mag(a) ); 
}
