window.onload = g_init;

var app = new App();

window['g_init'] = g_init;
function g_init() {
    app.init();
}

window['g_reInit'] = g_reInit;
function g_reInit() {
    app.removeEverything();
    app = new App();
    app.init();
}

window['g_runGame'] = g_runGame;
function g_runGame() {
    app.runGame();
}

window['g_preventDragging'] = g_preventDragging;
function g_preventDragging(event) {
    event.preventDefault();
}

window['g_test'] = g_test;
function g_test() {
    app.test();
}

window['g_runClockSeconds'] = g_runClockSeconds;
function g_runClockSeconds() {
    app.runClockSeconds();
}

window['g_debug'] = g_debug;
function g_debug(s) {
    app.debug(s);
}

window['g_clickedCastButton'] = g_clickedCastButton;
function g_clickedCastButton(playerI, buttonI) {
    app.clickedCastButton(playerI, buttonI);
}

window['g_dropSprite'] = g_dropSprite;
function g_dropSprite(centerX, centerY, spriteType, dropTicketGuid) {
    app.dropSprite(centerX, centerY, spriteType, dropTicketGuid);
}

window['g_clickedPause'] = g_clickedPause;
function g_clickedPause() {
    app.clickedPause();
}

window['g_clickedRestart'] = g_clickedRestart;
function g_clickedRestart() {
    app.clickedRestart();
}

window['g_clickedInfo'] = g_clickedInfo;
function g_clickedInfo() {
    app.clickedInfo();
}


/*** App ***/

App.prototype.init = function() {
    this.setBuildingProperties();
    this.createBackground();
    this.createDefaultSprites();
    this.createCastButtons();
    this.createMoneyBar();
    this.createPauseButton();
    this.createElmById('debug');

    this.intervalIdSeconds = setInterval( 'g_runClockSeconds()', 1000 );

    if (this.gameRuns) {
        if (this.useFixedInterval) {
            this.intervalId = setInterval( 'g_runGame()', this.intervalMS );
        }
        else {
            g_runGame();
        }
    }
}

App.prototype.runGame = function() {
    this.handleAll();
    this.showAll();
    this.removeDeadSprites();

    this.framesPerSecond++;
    if (!this.useFixedInterval) {
        if (this.gameRuns) {
            this.intervalId = setTimeout( 'g_runGame()', this.intervalMS );
        }
    }
}

App.prototype.handleAll = function() {
    this.handleSprites();
    this.handleMoney();
    this.handleCastButtons();
}

App.prototype.test = function() {
    if (this.allowTest) {
    }
}

App.prototype.showAll = function() {
    this.showSprites();
    this.showMoney();
    this.showCastButtons();
    this.playSounds();
}

App.prototype.getSpriteByGuid = function(guid) {
    var sprite = null;
    for (var i = 0; i < this.sprites.length && sprite == null; i++) {
        if (this.sprites[i].guid == guid) { sprite = this.sprites[i]; }
    }
    return sprite;
}

App.prototype.createCastButtons = function() {
    var marginX = 10;
    var marginBetweenX = 4;
    var marginY = 7;

    var rowY = new Array(882, 941);
    var player1x = new Array(8, 99, 190, 282, 373, 466, 524, 615, 708);

    var addOns = new Array(this.enumSpriteImproveService, this.enumSpriteImproveSecurity,
            this.enumSpriteTryFire, this.enumSpriteTryRob);
    for (var playerI = 0; playerI < this.playersMax; playerI++) {
        var i = 0;
        this.castButtons[playerI] = new Array();
        for (var xPositions = 0; xPositions < player1x.length; xPositions++) {
            for (var rowI = 0; rowI < 2; rowI++) {
                this.castButtons[playerI][i] = new CastButton();
                var castButton = this.castButtons[playerI][i];
                castButton.playerI = null;
                castButton.type = this.selectableSprites[i];

                castButton.isAddOn = addOns.inArray(castButton.type);
                if (castButton.isAddOn) { castButton.width = 51; }

                var sUpperLower = playerI == 0 ? 'upper' : 'lower';
                var name = this.spriteName[ this.selectableSprites[i] ];

                castButton.x = player1x[xPositions];
                castButton.y = rowY[rowI];

                castButton.cost = (castButton.x + castButton.width) * this.moneyPerPixel;

                if (playerI == 0) {
                    castButton.x = this.width - castButton.x - castButton.width;
                    castButton.y = this.height - castButton.y - castButton.height;
                }
                i++;
            }
        }
    }
}

App.prototype.handleCastButtons = function() {
    for (var playerI = 0; playerI < this.playersMax; playerI++) {
        for (var i = 0; i < this.castButtons[playerI].length; i++) {
            var castButton = this.castButtons[playerI][i];
            castButton.isClickable = this.money[playerI] > castButton.cost;
        }
    }
}

App.prototype.showCastButtons = function() {
    for (var playerI = 0; playerI < this.playersMax; playerI++) {
        for (var i = 0; i < this.castButtons[playerI].length; i++) {
            var castButton = this.castButtons[playerI][i];
            if (castButton.elm == null) {
                var sUpperLower = playerI == 0 ? 'upper' : 'lower';

                castButton.elm = document.createElement('div');
                castButton.elm.setAttribute('class', 'spriteButton');
                castButton.elm.setAttribute(this.clickEventName, 'g_clickedCastButton(' + playerI + ',' + i + ')');
                castButton.elm.setAttribute('style',
                        'background-image: url("image/sprite-button/' +
                        this.spriteName[castButton.type] + '-' + sUpperLower + '.png")');
                castButton.elm.style.left = castButton.x + 'px';
                castButton.elm.style.top = castButton.y + 'px';
                castButton.elm.setAttribute( 'ontouchmove', 'g_preventDragging(event)' );
                document.body.appendChild(castButton.elm);

                castButton.elmCross = document.createElement('div');
                if (castButton.isAddOn) {
                    castButton.elmCross.setAttribute('class', 'spriteButtonCrossAddOn');
                }
                else {
                    castButton.elmCross.setAttribute('class', 'spriteButtonCross');
                }

                castButton.elmCross.style.left = parseInt(castButton.x) + 'px';
                castButton.elmCross.style.top = parseInt(castButton.y) + 'px';
                castButton.elmCross.setAttribute( 'ontouchmove', 'g_preventDragging(event)' );
                document.body.appendChild(castButton.elmCross);
            }

            if (castButton.isClickable != castButton.isClickableOld) {
                castButton.elmCross.style.display = castButton.isClickable ? 'none' : 'block';
                castButton.isClickableOld = castButton.isClickable;
            }

            if (castButton.isHighlighted != castButton.isHighlightedOld) {
                if (castButton.isHighlighted) {
                    var elm = document.createElement('div');
                    elm.setAttribute('id', castButton.guid); 
                    elm.setAttribute('class', 'spriteButtonHighlight');
                    elm.style.left = castButton.x + 'px';
                    elm.style.top = castButton.y + 'px';
                    elm.setAttribute( 'ontouchmove', 'g_preventDragging(event)' );
                    document.body.appendChild(elm);
                }
                else {
                    this.removeElmById(castButton.guid);
                }
                castButton.isHighlightedOld = castButton.isHighlighted;
            }
    

        }
    }
}

App.prototype.clickedPause = function() {
    this.togglePause();
}

App.prototype.getWinnerNumber = function() {
    return this.money[0] > this.money[1] ? 0 : 1;
}

App.prototype.togglePause = function() {
    this.gameRuns = !this.gameRuns;
    var elm = document.getElementById('pauseButton');
    elm.style.backgroundImage = this.gameRuns ? 'url("image/pause-button.png")' : 'url("image/play-button.png")';

    if (this.gameRuns) {
        this.removeElmById('restartButton');
        this.removeElmById('infoButton');
        this.removeElmById('info');
        this.removeElmById('overlay');
        this.removeElmById( 'winner' + this.getWinnerNumber() );

        if (this.backgroundMusic != null) {
            this.backgroundMusic.pause();
            this.backgroundMusic = null;
        }

        if (this.allowTest) { setTimeout( 'g_test()', 2000 ); }
        this.intervalIdSeconds = setInterval( 'g_runClockSeconds()', 1000 );
    }
    else {
        var elmRestartButton = document.createElement('div');
        elmRestartButton.setAttribute('id', 'restartButton');
        elmRestartButton.setAttribute('class', 'restartButton');
        elmRestartButton.setAttribute( this.clickEventName, 'g_clickedRestart()' );
        document.body.appendChild(elmRestartButton);

        var elmInfoButton = document.createElement('div');
        elmInfoButton.setAttribute('id', 'infoButton');
        elmInfoButton.setAttribute('class', 'infoButton');
        elmInfoButton.setAttribute( this.clickEventName, 'g_clickedInfo()' );
        document.body.appendChild(elmInfoButton);

        this.createElmById('overlay');
        clearInterval(this.intervalIdSeconds);
    }

    if (this.specialPhase == this.enumAppPhaseGameOver && this.gameRuns) {
        this.restart();
    }
    else {
        if (this.useFixedInterval) {
            if (this.gameRuns) {
                this.intervalId = setInterval('g_runGame()', this.intervalMS);
            }
            else {
                clearInterval(this.intervalId);
            }
        }
    }
}

App.prototype.clickedRestart = function() {
    this.restart();
}

App.prototype.restart = function() {
    setTimeout('g_reInit()', 50);
}

App.prototype.clickedInfo = function() {
    var elm = document.getElementById('info');
    if (elm) {
        document.body.removeChild(elm);
        if (this.backgroundMusic != null) {
            this.backgroundMusic.pause();
            this.backgroundMusic = null;
        }
    }
    else {
        elm = document.createElement('div');
        elm.setAttribute('id', 'info');
        var s = '';
        s += '<strong>City Bucks</strong> is a strategic building game for two players. Drag and drop your buildings onto the map, then ' +
                'watch as citizens come to spend their money at your place. Satisfy their different needs and you can be a successful city ' +
                'builder. The first player to score $' + Misc.formatNumber(this.moneyMax) + ' wins.';
        s += "<p>City Bucks is like a board game... but with pieces magically moving. " +
                "You can play it at home, in a coffee shop, in bars, on trains and boats, " +
                "in the park and anywhere else, with friend, foe or family... " +
                "will you make a quick buck?</p>";
        s += "<p>City Bucks was created by Philipp Lenssen (you're playing version " + this.version + "). Got feedback or questions? Please email me at " +
                '<a href="mailto:philipp.lenssen@gmail.com?subject=City%20Bucks%20(version%20' + this.version + ')">philipp.lenssen@gmail.com</a></p>';
        s += '<p><strong>Thanks</strong> to everybody who tested, gave feedback &amp; helped. ' +
                'Thanks to the makers of PhoneGap, and the makers of the iPad!</p>';
        s += '<p><strong>More games</strong> and apps for the iPad &amp; iPhone <a href="http://outer-court.com/iphone/">are available ' +
                ' on my webpage</a>.</p>';
        elm.innerHTML = s;

        elm.setAttribute( 'ontouchmove', 'g_preventDragging(event)' );
        document.body.appendChild(elm);

        var soundFile = 'sound/theme.mp3';
        this.backgroundMusic = this.useAudioMethod ? new Audio(soundFile) : new Media(soundFile);
        this.backgroundMusic.play();
    }
}

App.prototype.runClockSeconds = function() {
    this.secondsCounter++;
    if (this.showFramesPerSecond) {
        var fpsToDisplay = this.framesPerSecond != null ? this.framesPerSecond : '-';
        this.debug('FPS: ' + fpsToDisplay);
    }

    this.framesPerSecond = 0;
    if (this.secondsCounter == 60) {
        this.secondsCounter = 0;
        this.minutesCounter++;
    }
}

App.prototype.clearFieldOf = function(requiredTypes) {
    for (var i = 0; i < this.sprites.length; i++) {
        if ( requiredTypes.inArray(this.sprites[i].type) ) {
            this.sprites[i].gone = true;
        }
    }
}

App.prototype.createElmById = function(id) {
    var elm = document.createElement('div');
    elm.setAttribute('id', id);
    elm.setAttribute( 'ontouchmove', 'g_preventDragging(event)' );
    document.body.appendChild(elm);
}

App.prototype.removeElmById = function(id) {
    var elm = document.getElementById(id);
    if (elm) { document.body.removeChild(elm); }
}

App.prototype.debug = function(text) {
    if (this.showDebugInfo) { Misc.setHtml('debug', text); }
}

App.prototype.debugAndStop = function(s) {
    var maxAlertsToShow = 10;
    this.debugCounter++;
    if (this.debugCounter <= maxAlertsToShow) { alert(s); }
}

App.prototype.dropSprite = function(centerX, centerY, spriteType, dropTicketGuid) {
    if (this.gameRuns) {
        if ( !Misc.isSet(dropTicketGuid) || ( Misc.isSet(this.dropTickets[dropTicketGuid]) && this.dropTickets[dropTicketGuid] ) ) {
            if ( Misc.isSet(dropTicketGuid) ) {
                this.dropTickets[dropTicketGuid] = false;
            }

            playerI = centerY < this.fieldMiddle ? 0 : 1;

            var sprite = this.getNewSprite();
            sprite.type = parseInt(spriteType);
            sprite.width = this.spriteSize[sprite.type].width;
            sprite.height = this.spriteSize[sprite.type].height;
            sprite.parentPlayer = playerI;
        
            sprite.x = parseInt(centerX - this.spriteSize[spriteType].width / 2);
            sprite.y = parseInt(centerY - this.spriteSize[spriteType].height / 2);

            this.removeRectangles(playerI);
            if (spriteType == this.enumSpriteBird) {
                this.addSound(this.enumSoundDroppedInWind);
            }
            else {
                this.addSound(this.enumSoundDroppedInWater);
            }
        }
    }
}

App.prototype.removeRectangles = function(playerI) {
    for (var i = 0; i < this.sprites.length; i++) {
        var sprite = this.sprites[i];
        if (sprite.type == this.enumSpriteRectangle) {
            if ( (playerI == 0 && sprite.y + sprite.height / 2 < this.fieldMiddle) ||
                    (playerI == 1 && sprite.y + sprite.height / 2 > this.fieldMiddle) ) {
                sprite.energy = 0;
            }
        }
    }
}

App.prototype.lowlightCastButtons = function(optionalPlayerI) {
    var playerMin = 0;
    var playerMax = this.playersMax - 1;
    if ( Misc.isSet(optionalPlayerI) ) {
        playerMin = optionalPlayerI;
        playerMax = optionalPlayerI;
    }

    for (var playerI = playerMin; playerI <= playerMax; playerI++) {
        for (var i = 0; i < this.selectableSprites.length; i++) {
            this.castButtons[playerI][i].isHighlighted = false;
        }
    }
}

App.prototype.clickedCastButton = function(playerI, buttonI) {
    if (this.gameRuns) {
        this.removeRectangles(playerI);

        playerI = parseInt(playerI);
        buttonI = parseInt(buttonI);

        var castButton = this.castButtons[playerI][buttonI];

        this.money[playerI] -= castButton.cost;
        if (this.money[playerI] < 0) { this.money[playerI] = 0; }

        var spriteType = this.selectableSprites[buttonI];
        this.lowlightCastButtons(playerI);
        castButton.isHighlighted = true;

        var dropTicketGuid = Misc.getRandomString(16);
        // todo: for each building base rectangle ...
    }
}

App.prototype.handleMoney = function() {
    if (this.specialPhase == null) {
        for (var i = 0; i < this.playersMax; i++) {
            if (this.money[i] < this.moneyMax) {
                this.money[i] += this.moneySpeed;
                if (this.money[i] > this.moneyMax) {
                    this.money[i] = this.moneyMax;
                }
            }
        }
    }
}

App.prototype.createMoneyBar = function() {
    for (var i = 0; i < this.playersMax; i++) {
        var sUpperLower = i == 0 ? 'upper' : 'lower';
        this.moneyElm[i] = document.createElement('div');
        this.moneyElm[i].setAttribute('class', 'moneyBar_' + sUpperLower);
        var y = i == 0 ? 0 : this.height - this.moneyBarHeight;
        this.moneyElm[i].setAttribute( 'ontouchmove', 'g_preventDragging(event)' );
        document.body.appendChild(this.moneyElm[i]);

        var id = 'moneyDisplay' + i;
        this.createElmById(id);
        this.moneyDisplayElm[i] = document.getElementById(id);
    }
}

App.prototype.createPauseButton = function() {
    var elm = document.createElement('div');
    elm.setAttribute('id', 'pauseButton');
    elm.setAttribute('class', 'pauseButton');
    elm.setAttribute(this.clickEventName, 'g_clickedPause()');
    elm.style.backgroundImage = this.gameRuns ? 'url("image/pause-button.png")' : 'url("image/play-button.png")';
    document.body.appendChild(elm);
}

App.prototype.createBackground = function() {
    var elmTop = document.createElement('div');
    elmTop.setAttribute('class', 'backgroundTop');
    elmTop.style.width = this.width + 'px';
    elmTop.style.height = this.paneHeight + 'px';
    elmTop.setAttribute( 'ontouchmove', 'g_preventDragging(event)' );
    document.body.appendChild(elmTop);

    var elmBottom = document.createElement('div');
    elmBottom.setAttribute('class', 'backgroundBottom');
    elmBottom.style.width = this.width + 'px';
    elmBottom.style.height = this.paneHeight + 'px';
    elmBottom.setAttribute( 'ontouchmove', 'g_preventDragging(event)' );
    document.body.appendChild(elmBottom);

    this.backgroundElm = document.getElementById('background');
    this.backgroundElm.setAttribute( 'ontouchmove', 'g_preventDragging(event)' );
}

App.prototype.createDefaultSprites = function() {
    if (this.useRandomDefaultSprites) {
        var includeTypes = new Array(this.enumSpriteCafe);
        for (var playerI = 0; playerI <= 1; playerI++) {
            // todo: for each building base ...
            /*
            var sprite = this.getNewSprite();
            sprite.type = includeTypes[ Misc.getRandomInt(0, includeTypes.length - 1) ];
            sprite.x = x;
            sprite.y = y;
            sprite.width = this.spriteSize[sprite.type].width;
            sprite.height = this.spriteSize[sprite.type].height;
            */
        }
    }

}

App.prototype.getNewSprite = function() {
    var i = this.sprites.length;
    this.sprites[i] = new Sprite();
    return this.sprites[i];
}

App.prototype.getDirection = function(speed) {
    var v = 0;
    if (speed < 0) {
        v = -1;
    }
    else if (speed > 0) {
        v = 1;
    }
    return v;
}

App.prototype.createSpriteCafe = function(x, playerToAttack, targetCenterX) {
    var sprite = this.getNewSprite();
    sprite.type = this.enumSpriteBlackbird;
    sprite.width = this.spriteSize[sprite.type].width;
    sprite.height = this.spriteSize[sprite.type].height;
    sprite.x = parseInt(x - sprite.width / 2);
    sprite.y = parseInt(this.fieldMiddle - sprite.height / 2);
}

App.prototype.createSpriteRectangle = function(centerX, centerY, spriteType, clickEvent, playerI, buttonI) {
    var sprite = this.getNewSprite();
    sprite.type = this.enumSpriteRectangle;
    sprite.width = this.spriteSize[sprite.type].width;
    sprite.height = this.spriteSize[sprite.type].height;
    sprite.x = parseInt(centerX - sprite.width / 2);;
    sprite.y = parseInt(centerY - sprite.height / 2);;
    sprite.cellsMax = 1;
    sprite.energy = 140;
    sprite.energySpeed = -1;
    sprite.directionDeterminesAppearance = false;
    sprite.explodesWhenLosingEnergy = false;
    sprite.explodesWhenDead = false;
    if (spriteType != null) { sprite.data['spriteType'] = spriteType; }
    if (clickEvent != null) { sprite.clickEvent = clickEvent; }
    sprite.data['playerI'] = playerI;
    sprite.data['buttonI'] = buttonI;
}

App.prototype.removeDeadSprites = function() {
    var removedRectangles = new Array();
    var removedRectanglesId = new Array();
    for (var i = 0; i < this.sprites.length; i++) {
        if ( Misc.isSet(this.sprites[i]) && (this.sprites[i].energy <= 0 || this.sprites[i].gone) ) {
            if (this.sprites[i].type == this.enumSpriteRectangle) {
                removedRectangles[ parseInt(this.sprites[i].data['playerI']) ] = true;
                removedRectanglesId[ parseInt(this.sprites[i].data['playerI']) ] = this.sprites[i].data['buttonI'];
            }
            document.body.removeChild(this.sprites[i].elm);
            this.sprites.splice(i, 1);
        }
    }

    if (removedRectangles.length > 0) {
        for (var playerI = 0; playerI < this.playersMax; playerI++) {
            if ( Misc.isSet(removedRectangles[playerI]) && removedRectangles[playerI] ) {
                var buttonI = removedRectanglesId[playerI];
                this.castButtons[playerI][buttonI].isHighlighted = false;
            }
        }
    }
}

App.prototype.removeEverything = function() {
    while ( document.body.childNodes.length >= 1 ) {
        document.body.removeChild(document.body.firstChild);
    }
    if (this.intervalIdSeconds != null) { clearInterval(this.intervalIdSeconds); }
    if (this.intervalIdMinutes != null) { clearInterval(this.intervalIdMinutes); }
}

App.prototype.handleSprites = function() {
    for (var i = 0; i < this.sprites.length; i++) {
        this.sprites[i].handleTypeSpecificBehavior(i);
    }
    for (var i = 0; i < this.sprites.length; i++) {
        this.sprites[i].handleGenericBehavior(i);
    }
}

App.prototype.showMoney = function() {
    for (var i = 0; i < this.playersMax; i++) {
        if (this.money[i] != this.moneyOld[i]) {
            var barWidth = parseInt(this.money[i] / this.moneyPerPixel);
            if (barWidth != this.barWidthOld) {
                this.moneyElm[i].style.width = barWidth + 'px';
            }

            this.moneyDisplayElm[i].innerHTML = '$' + Misc.formatNumber(this.money[i]);
            this.moneyOld[i] = this.money[i];
        }
    }
}

App.prototype.showSprites = function() {
    for (var i = 0; i < this.sprites.length; i++) {
        if (this.sprites[i].elm == null) {
            this.sprites[i].createSpriteImage( this.spriteName[ this.sprites[i].type ] +
                    '_x' + this.sprites[i].getDirectionAppearanceX() +
                    '_y' + this.sprites[i].getDirectionAppearanceY() + '_c1' );
        }

        if (this.sprites[i].energy <= 0) { this.sprites[i].elm.style.display = 'none'; }

        if ( parseInt(this.sprites[i].x) != this.sprites[i].xOld ) {
            this.sprites[i].elm.style.left = parseInt(this.sprites[i].x) + 'px';
            this.sprites[i].xOld = parseInt(this.sprites[i].x);
        }
        if ( parseInt(this.sprites[i].y) != this.sprites[i].yOld ) {
            this.sprites[i].elm.style.top = parseInt(this.sprites[i].y) + 'px';
            this.sprites[i].yOld = parseInt(this.sprites[i].y);
        }

        var cellRounded = Math.round(this.sprites[i].cell);
        if ( cellRounded != this.sprites[i].cellRoundedOld ||
                this.sprites[i].directionX != this.sprites[i].directionXOld ||
                this.sprites[i].directionY != this.sprites[i].directionYOld ) {
            var appearance = this.spriteName[ this.sprites[i].type ] +
                    '_x' + this.sprites[i].getDirectionAppearanceX() +
                    '_y' + this.sprites[i].getDirectionAppearanceY() +
                    '_c' + Math.round(this.sprites[i].cell);

            this.sprites[i].elm.setAttribute('class', 'sprite ' + appearance);
            this.sprites[i].directionXOld = this.sprites[i].directionX;
            this.sprites[i].directionYOld = this.sprites[i].directionY;
            this.sprites[i].cellRoundedOld = this.sprites[i].cellRounded;
        }
    }
}

App.prototype.getImagePath = function(imageName) {
    return 'image/sprite/' + imageName + '.png';
}

App.prototype.getClosestSpriteInSight = function(selfSprite, requiredTypes, requiredDirectionX, requiredDirectionY, requiredRelativePositionX, requiredRelativePositionY) {
    var closestSprite = null;
    var closestDistanceSoFar = null;
    var closestDistanceSoFarIndex = null;
    if (app.spritesCheckCollision) {
        for (var i = 0; i < this.sprites.length; i++) {
            var distance = app.getSpritesDistance(selfSprite, this.sprites[i])
            if (this.sprites[i] != selfSprite &&
                        distance <= selfSprite.sightRadius && (closestDistanceSoFar == null || distance < closestDistanceSoFar) ) {
                var isOk = true;

                if ( requiredTypes != null && !requiredTypes.inArray(this.sprites[i].type) ) { isOk = false; }
                if (isOk && requiredDirectionX != null && this.sprites[i].directionX != requiredDirectionX) { isOk = false; }
                if (isOk && requiredDirectionY != null && this.sprites[i].directionY != requiredDirectionY) { isOk = false; }

                if (isOk && requiredRelativePositionX != null) {
                    if (requiredRelativePositionX == -1) {
                        isOk = this.sprites[i].x + this.sprites[i].width / 2 < selfSprite.x + selfSprite.width / 2;
                    }
                    else if (requiredRelativePositionX == 1) {
                        isOk = this.sprites[i].x + this.sprites[i].width / 2 > selfSprite.x + selfSprite.width / 2;
                    }
                }
                if (isOk && requiredRelativePositionY != null) {
                    if (requiredRelativePositionY == -1) {
                        isOk = this.sprites[i].y + this.sprites[i].height / 2 < selfSprite.y + selfSprite.height / 2;
                    }
                    else if (requiredRelativePositionY == 1) {
                        isOk = this.sprites[i].y + this.sprites[i].height / 2 > selfSprite.y + selfSprite.height / 2;
                    }
                }

                if (isOk) {
                    closestDistanceSoFar = distance;
                    closestDistanceSoFarIndex = i;
                }
            }
        }
    }
    if (closestDistanceSoFar != null) {
        closestSprite = this.sprites[closestDistanceSoFarIndex];
    }
    return closestSprite;
}

App.prototype.getCollidingSprite = function(selfSprite, requiredTypes, typesToIgnoreIfByParentPlayer) {
    var collidingSprite = null;
    if (app.spritesCheckCollision) {
        var softer = 15;
        for (var i = 0; i < this.sprites.length && collidingSprite == null; i++) {
            if (this.sprites[i] != selfSprite) {
                var isOk = true;
                if (selfSprite.parentGuid == this.sprites[i].guid) { isOk = false; }
                if ( isOk && requiredTypes != null && !requiredTypes.inArray(this.sprites[i].type) ) { isOk = false; }
                if ( isOk ) {
                    var a = selfSprite, b = this.sprites[i];
                    var doesCollide = a.x <= b.x + b.width - softer && a.x + a.width >= b.x + softer &&
                            a.y <= b.y + b.height - softer && a.y + a.height >= b.y + softer;
                    isOk = doesCollide;
                }
                if (isOk) {
                    if ( Misc.isSet(typesToIgnoreIfByParentPlayer) && Misc.isSet(this.parentPlayer) != null &&
                            typesToIgnoreIfByParentPlayer.inArray(this.sprites[i].type) &&
                            selfSprite.parentPlayer == this.sprites[i].parentPlayer) {
                        isOk = false;
                    }
                }
    
                if (isOk) { collidingSprite = this.sprites[i]; }
            }
        }
    }
    return collidingSprite;
}

App.prototype.getSpritesDistance = function(spriteA, spriteB) {
    var distanceX = spriteA.x - spriteB.x;
    var distanceY = spriteA.y - spriteB.y;
    return Math.sqrt(distanceX * distanceX + distanceY * distanceY);
}

App.prototype.spriteMayPerformCalculationNow = function() {
    return Misc.getChance(15);
}

App.prototype.addSound = function(enumSound) {
    this.soundsToPlay[this.soundsToPlay.length] = enumSound;
}

App.prototype.playSounds = function() {
    if (this.doPlaySoundFX) {
        this.soundPlayEnergy++;

        for (var i = 0; i < this.soundsToPlay.length; i++) {
            var soundIsImportant = Misc.isSet( this.soundIsImportant[ this.soundsToPlay[i] ] ) && this.soundIsImportant[ this.soundsToPlay[i] ];
            if (this.soundPlayEnergy >= this.soundPlayEnergyNeeded || soundIsImportant) {
                var soundFile = 'sound/' + this.soundName[ this.soundsToPlay[i] ] + '.mp3';
                var cacheName = soundFile + '_random_' + Misc.getRandomInt(0, this.maxSoundsSameAtOnce - 1);
                if ( !Misc.isSet(this.soundCache[cacheName]) ) {
                    this.soundCache[cacheName] = this.useAudioMethod ? new Audio(soundFile) : new Media(soundFile);
                }
                this.soundCache[cacheName].play();
                this.soundPlayEnergy = 0;         
            }
        }

        this.soundsToPlay = new Array();
    }
}

App.prototype.setBuildingProperties = function() {
    var building = null;
    var requiredCost = null;
    var requiredOffersSum = null;

    /***********************************/

    building = new Building();
    building.type = this.enumSpriteHome;
    building.offers.money = 10;
    building.offers.sleep = 5;
    building.wantsAreRandomizedAfterVisit = true;
    this.baseBuildings[building.type] = building;


    /***********************************/
    requiredCost = 1;
    requiredOffersSum = 9;

    building = new Building();
    building.type = this.enumSpriteShop;
    building.offers.food = 1;
    building.offers.drinks = 1;
    building.offers.shopping = 6;
    building.offers.culture = 1;
    building.creationCost = requiredCost;
    building.createsWants.money = requiredCost;
    building.createsWants.sleep = 1;
    building.verifyRequirements(requiredOffersSum, this.spriteName[building.type]);
    this.baseBuildings[building.type] = building;

    building = new Building();
    building.type = this.enumSpriteCafe;
    building.offers.food = 1;
    building.offers.drinks = 5;
    building.offers.company = 1;
    building.offers.privacy = 2;
    building.creationCost = requiredCost;
    building.createsWants.money = requiredCost;
    building.createsWants.sleep = 1;
    building.verifyRequirements(requiredOffersSum, this.spriteName[building.type]);
    this.baseBuildings[building.type] = building;


    /***********************************/
    requiredCost = 2;
    requiredOffersSum = 11;

    building = new Building();
    building.type = this.enumSpriteFastfood;
    building.offers.food = 6;
    building.offers.drinks = 3;
    building.offers.entertainment = 1;
    building.offers.privacy = 1;
    building.creationCost = requiredCost;
    building.verifyRequirements(requiredOffersSum, this.spriteName[building.type]);
    building.createsWants.money = requiredCost;
    building.createsWants.sleep = 1;
    this.baseBuildings[building.type] = building;

    building = new Building();
    building.type = this.enumSpritePark;
    building.offers.drinks = 1;
    building.offers.culture = 1;
    building.offers.sleep = 1;
    building.offers.entertainment = 2;
    building.offers.privacy = 4;
    building.offers.company = 2;
    building.creationCost = requiredCost;
    building.createsWants.money = requiredCost;
    building.createsWants.sleep = 1;
    building.verifyRequirements(requiredOffersSum, this.spriteName[building.type]);
    this.baseBuildings[building.type] = building;

    /***********************************/
    requiredCost = 3;
    requiredOffersSum = 13;

    building = new Building();
    building.type = this.enumSpriteHotel;
    building.offers.food = 2;
    building.offers.sleep = 6;
    building.offers.privacy = 5;
    building.creationCost = requiredCost;
    building.createsWants.sleep = 1;
    building.verifyRequirements(requiredOffersSum, this.spriteName[building.type]);
    this.baseBuildings[building.type] = building;

    building = new Building();
    building.type = this.enumSpriteBookstore;
    building.offers.shopping = 6;
    building.offers.culture = 4;
    building.offers.company = 1;
    building.offers.privacy = 1;
    building.offers.drinks = 1;
    building.creationCost = requiredCost;
    building.createsWants.money = requiredCost;
    building.createsWants.sleep = 1;
    building.verifyRequirements(requiredOffersSum, this.spriteName[building.type]);
    this.baseBuildings[building.type] = building;


    /***********************************/
    requiredCost = 4;
    requiredOffersSum = 15;

    building = new Building();
    building.type = this.enumSpriteNightclub;
    building.offers.food = 1;
    building.offers.drinks = 5;
    building.offers.privacy = 2;
    building.offers.entertainment = 3;
    building.offers.company = 4;
    building.creationCost = requiredCost;
    building.createsWants.sleep = 3;
    building.createsWants.company = 2;
    building.verifyRequirements(requiredOffersSum, this.spriteName[building.type]);
    this.baseBuildings[building.type] = building;

    building = new Building();
    building.type = this.enumSpriteRestaurant;
    building.offers.food = 7;
    building.offers.drinks = 5;
    building.offers.privacy = 3;
    building.creationCost = requiredCost;
    building.createsWants.money = requiredCost;
    building.createsWants.sleep = 1;
    building.verifyRequirements(requiredOffersSum, this.spriteName[building.type]);
    this.baseBuildings[building.type] = building;


    /***********************************/
    requiredCost = 5;
    requiredOffersSum = 17;

    building = new Building();
    building.type = this.enumSpriteMuseum;
    building.offers.privacy = 1;
    building.offers.entertainment = 4;
    building.offers.culture = 12;
    building.creationCost = requiredCost;
    building.createsWants.money = 3;
    building.createsWants.sleep = 1;
    building.verifyRequirements(requiredOffersSum, this.spriteName[building.type]);
    this.baseBuildings[building.type] = building;

    building = new Building();
    building.type = this.enumSpriteKaraoke;
    building.offers.drinks = 2;
    building.offers.privacy = 5;
    building.offers.entertainment = 4;
    building.offers.company = 5;
    building.offers.culture = 1;
    building.creationCost = requiredCost;
    building.createsWants.money = requiredCost;
    building.createsWants.sleep = 3;
    building.createsWants.company = 2;
    building.verifyRequirements(requiredOffersSum, this.spriteName[building.type]);
    this.baseBuildings[building.type] = building;


    /***********************************/
    requiredCost = 6.5;
    requiredOffersSum = 20;

    building = new Building();
    building.type = this.enumSpriteCinema;
    building.offers.privacy = 3;
    building.offers.drinks = 1;
    building.offers.entertainment = 14;
    building.offers.culture = 2;
    building.creationCost = requiredCost;
    building.createsWants.money = 4;
    building.createsWants.sleep = 1;
    this.baseBuildings[building.type] = building;
    building.verifyRequirements(requiredOffersSum, this.spriteName[building.type]);

    building = new Building();
    building.type = this.enumSpriteShoppingmall;
    building.offers.shopping = 9;
    building.offers.food = 3;
    building.offers.drinks = 3;
    building.offers.entertainment = 2;
    building.offers.company = 2;
    building.offers.privacy = 1;
    building.creationCost = requiredCost;
    building.createsWants.money = requiredCost;
    building.createsWants.sleep = 2;
    building.verifyRequirements(requiredOffersSum, this.spriteName[building.type]);
    this.baseBuildings[building.type] = building;

    /***********************************/
    requiredCost = 7.5;
    requiredOffersSum = 22;

    building = new Building();
    building.type = this.enumSpriteDeluxehotel;
    building.offers.food = 3;
    building.offers.drinks = 4;
    building.offers.entertainment = 2;
    building.offers.sleep = 7;
    building.offers.privacy = 6;
    building.creationCost = requiredCost;
    building.createsWants.money = requiredCost;
    building.createsWants.sleep = 1;
    building.verifyRequirements(requiredOffersSum, this.spriteName[building.type]);
    this.baseBuildings[building.type] = building;

    building = new Building();
    building.type = this.enumSpriteVipclub;
    building.offers.food = 1;
    building.offers.drinks = 5;
    building.offers.entertainment = 8;
    building.offers.privacy = 2;
    building.offers.company = 3;
    building.offers.money = 3;
    building.creationCost = requiredCost;
    building.createsWants.money = requiredCost + building.offers.money + 1;
    building.createsWants.sleep = 3;
    building.createsWants.company = 2;
    building.verifyRequirements(requiredOffersSum, this.spriteName[building.type]);
    this.baseBuildings[building.type] = building;
}

function App() {
    this.version  = '0.9';
    var isIPad = navigator.userAgent.match(/iPad/i) != null;
    this.isLocalTest = !isIPad;
    this.useAudioMethod = this.isLocalTest;
    this.showDebugInfo = true;

    this.spritesCheckCollision = true;
    this.speedFactor = 4;
    this.useFixedInterval = true;
    this.intervalMS = this.useFixedInterval ? 100 : 0;
    this.useRandomDefaultSprites = false;
    this.clickEventName = this.isLocalTest ? 'onclick' : 'ontouchstart';
    this.gameRuns = true;
    this.allowTest = true;

    this.paneHeight = 148;
    this.width = 768;
    this.height = 1024;
    this.playersMax = 2;
    this.money = new Array();
    this.moneyOld = new Array();
    this.moneyMax = 100000000;
    this.moneyElm = new Array();
    this.moneySpeed = 1000; // 1000

    this.showFramesPerSecond = false;
    this.moneyDisplayElm = new Array();

    for (var i = 0; i < this.playersMax; i++) {
        this.money[i] = 380000;
        this.moneyOld[i] = null;
        this.moneyDisplayElm[i] = null;
    }

    this.moneyBarHeight = 109;
    this.castSpritebuttonWidth = 103;
    this.castSpritebuttonHeight = 103;

    this.backgroundElm = null;
    this.backgroundCounter = 1;

    this.fieldMinX = 0;
    this.fieldMaxX = this.width;
    this.fieldMinY = this.paneHeight;
    this.fieldMaxY = this.height - this.paneHeight;
    this.fieldMiddle = parseInt(this.height / 2);
    this.fieldShoreOffset = 20;

    this.debugCounter = 0;
    this.sprites = new Array();
    this.framesPerSecond = null;

    var enumCounter = 1;
    this.enumSpriteShop = enumCounter++;
    this.enumSpriteCafe = enumCounter++;
    this.enumSpriteFastfood = enumCounter++;
    this.enumSpritePark = enumCounter++;
    this.enumSpriteHotel = enumCounter++;
    this.enumSpriteBookstore = enumCounter++;
    this.enumSpriteNightclub = enumCounter++;
    this.enumSpriteRestaurant = enumCounter++;
    this.enumSpriteMuseum = enumCounter++;
    this.enumSpriteKaraoke = enumCounter++;
    this.enumSpriteImproveService = enumCounter++;
    this.enumSpriteImproveSecurity = enumCounter++;
    this.enumSpriteCinema = enumCounter++;
    this.enumSpriteShoppingmall = enumCounter++;
    this.enumSpriteDeluxehotel = enumCounter++;
    this.enumSpriteVipclub = enumCounter++;
    this.enumSpriteTryFire = enumCounter++;
    this.enumSpriteTryRob = enumCounter++;

    this.enumSpriteHumanPlayer0 = enumCounter++;
    this.enumSpriteHumanPlayer1 = enumCounter++;
    this.enumSpriteHumanServiceBadge = enumCounter++;
    this.enumSpriteHumanSecurityBadge = enumCounter++;
    this.enumSpriteHome = enumCounter++;

    this.spriteName = new Array();
    this.spriteName[this.enumSpriteShop] = 'shop';
    this.spriteName[this.enumSpriteCafe] = 'cafe';
    this.spriteName[this.enumSpriteFastfood] = 'fastfood';
    this.spriteName[this.enumSpritePark] = 'park';
    this.spriteName[this.enumSpriteHotel] = 'hotel';
    this.spriteName[this.enumSpriteBookstore] = 'bookstore';
    this.spriteName[this.enumSpriteNightclub] = 'nightclub';
    this.spriteName[this.enumSpriteRestaurant] = 'restaurant';
    this.spriteName[this.enumSpriteMuseum] = 'museum';
    this.spriteName[this.enumSpriteKaraoke] = 'karaoke';
    this.spriteName[this.enumSpriteImproveService] = 'improve-service';
    this.spriteName[this.enumSpriteImproveSecurity] = 'improve-security';
    this.spriteName[this.enumSpriteCinema] = 'cinema';
    this.spriteName[this.enumSpriteShoppingmall] = 'shoppingmall';
    this.spriteName[this.enumSpriteDeluxehotel] = 'deluxehotel';
    this.spriteName[this.enumSpriteVipclub] = 'vipclub';
    this.spriteName[this.enumSpriteTryFire] = 'try-fire';
    this.spriteName[this.enumSpriteTryRob] = 'try-rob';

    this.spriteName[this.enumSpriteHuman] = 'human';
    this.spriteName[this.enumSpriteHumanPlayer0] = 'human0';
    this.spriteName[this.enumSpriteHumanPlayer1] = 'human1';
    this.spriteName[this.enumSpriteServiceBadge] = 'service-badge';
    this.spriteName[this.enumSpriteSecurityBadge] = 'security-badge';
    this.spriteName[this.enumSpriteHome] = 'home';

    var i = 0;
    this.selectableSprites = new Array();
    this.selectableSprites[i++] = this.enumSpriteShop;
    this.selectableSprites[i++] = this.enumSpriteCafe;
    this.selectableSprites[i++] = this.enumSpriteFastfood;
    this.selectableSprites[i++] = this.enumSpritePark;
    this.selectableSprites[i++] = this.enumSpriteHotel;
    this.selectableSprites[i++] = this.enumSpriteBookstore;
    this.selectableSprites[i++] = this.enumSpriteNightclub;
    this.selectableSprites[i++] = this.enumSpriteRestaurant;
    this.selectableSprites[i++] = this.enumSpriteMuseum;
    this.selectableSprites[i++] = this.enumSpriteKaraoke;
    this.selectableSprites[i++] = this.enumSpriteImproveService;
    this.selectableSprites[i++] = this.enumSpriteImproveSecurity;
    this.selectableSprites[i++] = this.enumSpriteCinema;
    this.selectableSprites[i++] = this.enumSpriteShoppingmall;
    this.selectableSprites[i++] = this.enumSpriteDeluxehotel;
    this.selectableSprites[i++] = this.enumSpriteVipclub;
    this.selectableSprites[i++] = this.enumSpriteTryFire;
    this.selectableSprites[i++] = this.enumSpriteTryRob;

    this.soundsToPlay = new Array();

    enumCounter = 1;
    this.enumSoundTest = enumCounter++;

    this.specialPhase = null;
    enumCounter = 1;
    this.enumAppPhaseGameOver = enumCounter++;

    this.soundName = new Array();
    this.soundName[this.enumSoundTest] = 'test';

    this.soundIsImportant = new Array();
    this.soundIsImportant[this.enumSoundTest] = true;

    this.maxSoundsSameAtOnce = 2;
    this.soundCache = new Object();
    this.doPlaySoundFX = true;

    this.castButtons = new Array();
    this.specialPhaseCounter = null;

    this.secondsCounter = 0;
    this.minutesCounter = 0;

    this.soundPlayEnergyNeeded = 2;
    this.soundPlayEnergy = 0;

    this.intervalId = null;
    this.intervalIdSeconds = null;

    this.spriteSize = new Array();
    this.spriteSize[this.enumSpriteCafe] = new Size(56, 99);

    this.backgroundMusic = null;
    this.dropTickets = new Object();

    this.baseBuildings = new Object();
    this.barWidthOld = null;
    this.moneyPerPixel = 5000;
}
