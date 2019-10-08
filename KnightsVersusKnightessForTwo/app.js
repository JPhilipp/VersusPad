window.onload = g_init;

var app = null;

function g_init() { app = new App(); app.init(); }
function g_handleAndShowAll() { app.handleAndShowAll(); }
function g_runClockSeconds() { app.runClockSeconds(); }

/*************/


App.prototype.init = function() {
    this.createBackground();
    this.createMenuButton();
    this.createTestWarriors();
    this.startIntervals();
    // this.newsDialog.handle();
}

App.prototype.createTestWarriors = function() {
    var width = 100;
    var subtypes = new Array(Enum.maleArcher, Enum.maleKnight, Enum.maleBerserker, Enum.maleDrummer, Enum.maleShieldbearer);
    var borderOffset = 10;
    for (var i = 0; i < subtypes.length; i++) {
        this.createWarrior(subtypes[i], borderOffset + width * i, subtypes[i] == Enum.maleBerserker, subtypes[i] == Enum.maleBerserker);
    }

    subtypes = new Array(Enum.femaleKnight, Enum.femaleBerserker, Enum.femaleShieldbearer, Enum.femaleFlagbearer, Enum.femaleArcher);
    for (var i = 0; i < subtypes.length; i++) {
        this.createWarrior(subtypes[i], this.width - borderOffset + width * i - 500, false, false);
    }
}

App.prototype.handleAndShowAll = function() {
    this.framesPerSecond++;

    this.removeDeadSprites();
    this.handleSprites();
    this.playSounds();
    // this.checkForGameOver();

    this.showSprites();
    // this.showScore();
}

App.prototype.checkForGameOver = function() {
    for (var i = 0; i < this.playersMax; i++) {
        if (this.score[i] >= this.scoreMax) {
            clearInterval(this.intervalId);
            // this.showWinnerScreen();
        }
    }
}

App.prototype.runClockSeconds = function() {
    this.secondsCounter++;
    if (this.secondsCounter == 60) {
        this.secondsCounter = 0;
        this.minutesCounter++;
    }

    var allSeconds = this.minutesCounter * 60 + this.secondsCounter;
    if ( allSeconds % this.eventFrequencySeconds == 0 ) {
        this.handleSpecialEvent();
        this.eventFrequencySeconds = Misc.getRandomInt(
                this.eventFrequencyMedium - this.eventFrequencyVariance, this.eventFrequencyMedium + this.eventFrequencyVariance);
    }

    if (this.showFramesPerSecond) {
        var fpsToDisplay = this.framesPerSecond != null ? this.framesPerSecond : '-';
        this.debug('FPS ' + fpsToDisplay + '/' + this.FPSMax + ' &nbsp;|&nbsp; ' +
                Misc.pad(this.minutesCounter) + ':' + Misc.pad(this.secondsCounter) );
    }

    this.framesPerSecond = 0;
}

App.prototype.createMenuButton = function() {
    var elm = document.createElement('div');
    elm.setAttribute('id', 'menuButton');
    elm.setAttribute( this.clickEventName, 'app.clickedMenu()' );
    document.body.appendChild(elm);
}

App.prototype.clickedMenu = function() {
    if (this.intervalId == null) {
        Misc.removeElmById('menuBackground');
        this.startIntervals();
    }
    else {
        Misc.createElmById('menuBackground');
        clearInterval(this.intervalId)
        clearInterval(this.intervalIdSeconds)
        this.intervalId = null;
        this.intervalIdSeconds = null;
    }
}

App.prototype.startIntervals = function() {
    this.intervalId = setInterval(g_handleAndShowAll, this.intervalMS);
    this.intervalIdSeconds = setInterval(g_runClockSeconds, this.clockSecondsMS);
}

App.prototype.createBackground = function() {
    var max = 3;
    var width = 341;
    var widthMiddle = 342;
    var height = 256;
    if (this.isLocalTest) { widthMiddle -= 1; }

    this.createBackgroundTile(0, 0, 0, 0, width, height);
    this.createBackgroundTile(1, 0, width, 0, widthMiddle, height);
    this.createBackgroundTile(2, 0, width + widthMiddle, 0, width, height);

    this.createBackgroundTile(0, 1, 0, height, width, height);
    this.createBackgroundTile(1, 1, width, height, widthMiddle, height);
    this.createBackgroundTile(2, 1, width + widthMiddle, height, width, height);

    this.createBackgroundTile(0, 2, 0, height * 2, width, height);
    this.createBackgroundTile(1, 2, width, height * 2, widthMiddle, height);
    this.createBackgroundTile(2, 2, width + widthMiddle, height * 2, width, height);
}

App.prototype.createBackgroundTile = function(gridX, gridY, x, y, width, height) {
    var elm = document.createElement('div');
    elm.setAttribute('class', 'backgroundTile');
    elm.style.backgroundImage = 'url("image/background/' + gridX + '-' + gridY + '.png")';
    elm.style.left = x + 'px';
    elm.style.top = y + 'px';
    elm.style.width = width + 'px';
    elm.style.height = height + 'px';
    document.body.appendChild(elm);
}

App.prototype.createWarrior = function(subtype, x, debugMe, showPaddingRectangle) {
    var sprite = new Sprite();
    sprite.type = Enum.typeWarrior;
    sprite.subtype = subtype;

    var gender = subtype >= Enum.maleSubtypeMin && subtype <= Enum.maleSubtypeMax ? Enum.male : Enum.female;

    sprite.setSizeBasedOnType();
    sprite.speedDeterminesDirection = false;
    sprite.directionDeterminesAppearance = false;
    sprite.energy = 10;

    var marginX = 84;
    if (gender == Enum.male) {
        sprite.directionX = 1;
        sprite.x = marginX;
    }
    else {
        sprite.directionX = -1;
        sprite.x = this.width - marginX - sprite.width;
    }

    sprite.y = 495;
    sprite.zIndex = 500;
    this.warriorCreatedCount[gender]++;
    if ( this.warriorCreatedCount[gender] % 2 == 0 ) {
        sprite.y += 14;
        sprite.zIndex = 1000;
    }

    sprite.x = x;

    sprite.cellsSpeed = .0000001; // .2

    sprite.phase = new Phase(Enum.phaseStand);
    sprite.phasesWithOwnAppearance = new Array(Enum.phaseStand, Enum.phaseWalk,
            Enum.phasePrepareAttack, Enum.phaseAttack, Enum.phaseShock, Enum.phaseDefend, Enum.phaseMotivate);

    sprite.cellsMax = 1;
    sprite.debugMe = debugMe;

    sprite.warrior = new Warrior(gender, subtype, sprite.debugMe);
    sprite.padding = new Padding(75, 28, 75, 28);

    if (showPaddingRectangle) {
        // this.createRectangle( sprite.getPaddedRectangle(), sprite.guid );
    }

    this.sprites[this.sprites.length] = sprite;
}

App.prototype.createPlaceholder = function(parentGuid, rectangle) {
    var sprite = new Sprite();
    sprite.type = Enum.typePlaceholder;
    sprite.x = rectangle.x1;
    sprite.y = rectangle.y1;
    sprite.width = rectangle.x2 - rectangle.x1;
    sprite.height = rectangle.x2 - rectangle.x1;
    sprite.speedDeterminesDirection = false;
    sprite.directionDeterminesAppearance = false;
    sprite.parentGuid = parentGuid;
    sprite.hasImage = false;
    sprite.disappearsWithParent = true;

    // this.createRectangle( sprite.getPaddedRectangle(), sprite.guid );

    this.sprites[this.sprites.length] = sprite;
}

App.prototype.createWarriorGhost = function(subtype, x, y, speedX, speedY) {
    var sprite = new Sprite();
    sprite.type = Enum.typeWarriorGhost;
    sprite.subtype = subtype;
    sprite.setSizeBasedOnType();
    sprite.speedDeterminesDirection = false;
    sprite.directionDeterminesAppearance = false;
    sprite.x = x;
    sprite.y = y;
    sprite.speed = new Vector(speedX, speedY);

    sprite.appearance = this.spriteName[Enum.phaseGhost];
    sprite.reactsToGravity = true;
    sprite.energy = 30;
    sprite.energySpeed = -1;

    this.sprites[this.sprites.length] = sprite;
}

App.prototype.createDamageWave = function(centerPos, parentGuid, speedX, speedY) {
    var sprite = new Sprite();
    sprite.type = Enum.typeDamageWave;
    sprite.hasImage = false;
    sprite.width = 30;
    sprite.height = 30;
    sprite.setPosByCenter(centerPos);
    sprite.speed = new Vector(speedX, speedY);

    sprite.directionX = this.getDirection(speedX);
    sprite.directionY = this.getDirection(speedY);

    sprite.parentGuid = parentGuid;

    sprite.x += speedX * 3;
    sprite.y += speedY * 3;

    sprite.energy = 3;
    sprite.energySpeed = -1;

    // this.createRectangle( sprite.getPaddedRectangle(), sprite.guid, 4 );

    this.sprites[this.sprites.length] = sprite;
}

App.prototype.createEffect = function(subtype, centerPos, speedX, speedY, energy) {
    var sprite = new Sprite();
    sprite.type = Enum.typeEffect;
    sprite.subtype = subtype;

    sprite.width = 68;
    sprite.height = 50;
    sprite.setPosByCenter(centerPos);
    sprite.speed = new Vector(speedX, speedY);

    sprite.speedDeterminesDirection = true;
    sprite.zIndex = 1500;
    sprite.energy = energy;
    sprite.energySpeed = -1;
    sprite.canCollide = false;

    // this.createRectangle( sprite.getPaddedRectangle(), sprite.guid, 4 );

    this.sprites[this.sprites.length] = sprite;
}

App.prototype.createRectangle = function(rectangle, optionalParentGuid, borderWidth) {
    var sprite = new Sprite();
    sprite.type = Enum.typeRectangle;

    borderWidth = Misc.isSet(borderWidth) ? borderWidth : 4;
    sprite.x = rectangle.x1 - parseInt(borderWidth / 2);
    sprite.y = rectangle.y1 - parseInt(borderWidth / 2);
    sprite.width = rectangle.x2 - rectangle.x1;
    sprite.height = rectangle.y2 - rectangle.y1;

    if ( Misc.isSet(optionalParentGuid) ) {
        sprite.parentGuid = optionalParentGuid;
        sprite.disappearsWithParent = true;
        sprite.movesWithParent = true;
    }

    sprite.hasImage = false;
    sprite.zIndex = 2000;
    sprite.canCollide = false;

    this.sprites[this.sprites.length] = sprite;
}

App.prototype.createTapIcon = function(parentGuid, gender, centerPos) {
    var sprite = new Sprite();
    sprite.type = Enum.typeTapIcon;
    sprite.subtype = gender;

    sprite.setSizeBasedOnType();
    sprite.speedDeterminesDirection = false;
    sprite.directionDeterminesAppearance = false;

    sprite.setPosByCenter(centerPos);

    sprite.parentGuid = parentGuid;
    sprite.disappearsWithParent = true;
    sprite.movesWithParent = true;
    sprite.zIndex = 2500;
    sprite.clickEvent = 'app.clickedTapIcon("' + sprite.guid + '")';
    sprite.imagePosPercent = new Position(50, 70);
    sprite.canCollide = false;

    this.sprites[this.sprites.length] = sprite;
}

App.prototype.clickedTapIcon = function(guid) {
    var sprite = this.getSpriteByGuid(guid);
    if ( Misc.isSet(sprite) ) {
        var parentSprite = this.getSpriteByGuid(sprite.parentGuid);
        if ( Misc.isSet(parentSprite) ) {
            sprite.gone = true;
            parentSprite.warrior.actionEnergy = Misc.getRandomInt(0, 20);
            parentSprite.warrior.actionEnergySpeed = 1;
            parentSprite.warrior.doAct = true;
        }
    }
}

App.prototype.handleSpecialEvent = function() {
    var minSecondsForSpecial = 20;
    var allSeconds = this.minutesCounter * 60 + this.secondsCounter;
    if (allSeconds >= minSecondsForSpecial) {
        var randomI = Misc.getRandomInt(1, 1);
        switch (randomI) {
            case 1:
                this.createEagle(Enum.bomb); // Enum.bomb or Enum.healthPack
                break;
        }
    }
}

App.prototype.createEagle = function(packType) {
    /*
    var sprite = new Sprite();
    sprite.type = Enum.typeEagle;
    sprite.setSizeBasedOnType();
    sprite.speedDeterminesDirection = false;
    sprite.directionDeterminesAppearance = false;
    sprite.energy = 10;
    this.sprites[this.sprites.length] = sprite;
    */
}

App.prototype.debug = function(text) {
    if (this.showDebugInfo) {
        if (this.debugElm == null) {
            this.debugElm = Misc.createElmById('debug');
            this.debugElm.setAttribute( 'onclick', 'app.closeDebug()' );
        }
        this.debugElm.innerHTML = text;
    }
}

App.prototype.debugAndStop = function(s) {
    if (this.showDebugInfo) {
        var maxAlertsToShow = 6;
        this.debugCounter++;
        if (this.debugCounter <= maxAlertsToShow) {
            if (this.debugCounter == maxAlertsToShow) { s += "\r\n\r\n" + '[Further alerts will be hidden]'; }
            alert(s);
        }
    }
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

App.prototype.removeSpriteByParentGuid = function(type, parentGuid) {
    for (var i = 0; i < this.sprites.length; i++) {
        var sprite = this.sprites[i];
        if (sprite.type == type && sprite.parentGuid == parentGuid) { sprite.gone = true; }
    }
}

App.prototype.removeDeadSprites = function() {
    for (var i = 0; i < this.sprites.length; i++) {
        if ( Misc.isSet(this.sprites[i]) && (this.sprites[i].energy <= 0 || this.sprites[i].gone) ) {
            this.setChildrenToGone(this.sprites[i].guid);
        }
    }

    for (var i = 0; i < this.sprites.length; i++) {
        if ( Misc.isSet(this.sprites[i]) && (this.sprites[i].energy <= 0 || this.sprites[i].gone) ) {
            if (this.sprites[i].elmInited) {
                document.body.removeChild(this.sprites[i].elm);
            }
            this.sprites[i].elm = null;
            this.sprites.splice(i, 1);
        }
    }
}

App.prototype.setChildrenToGone = function(parentGuid) {
    for (var i = 0; i < this.sprites.length; i++) {
        if (this.sprites[i].disappearsWithParent && this.sprites[i].parentGuid == parentGuid) {
            this.sprites[i].gone = true;
        }
    }
}

App.prototype.removeEverything = function() {
    while ( document.body.childNodes.length >= 1 ) {
        document.body.removeChild(document.body.firstChild);
    }
    if (this.intervalId != null) { clearInterval(this.intervalId); }
    if (this.intervalIdSeconds != null) { clearInterval(this.intervalIdSeconds); }
}

App.prototype.handleSprites = function() {
    for (var i = 0; i < this.sprites.length; i++) {
        this.sprites[i].handleTypeSpecificBehavior();
    }
    for (var i = 0; i < this.sprites.length; i++) {
        this.sprites[i].handleGenericBehavior();
    }
    this.moveChildrenWithParents();
}

App.prototype.moveChildrenWithParents = function() {
    for (var i = 0; i < this.sprites.length; i++) {
        this.sprites[i].handleMoveChildWithParent();
    }
}

App.prototype.showScore = function() {
    var workaroundChanceForDisplayBug = 4;
    for (var i = 0; i < this.playersMax; i++) {
        if ( this.score[i] != this.scoreOld[i] || Misc.getChance(workaroundChanceForDisplayBug) ) {
            // ...
        }
    }
}

App.prototype.showSprites = function() {
    this.framesPerSecond++;
    for (var i = 0; i < this.sprites.length; i++) {
        this.sprites[i].show();
    }
}

App.prototype.getImagePath = function(imageName) {
    return 'image/' + imageName + '.png';
}

App.prototype.getCollidingSprite = function(selfSprite, requiredTypes) {
    requiredTypes = Misc.toArray(requiredTypes);
    var collideWithChildren = false;

    var collidingSprite = null;
    if (selfSprite.canCollide) {
        for (var i = 0; i < this.sprites.length && collidingSprite == null; i++) {
            if (this.sprites[i] != selfSprite && this.sprites[i].canCollide) {
                var isOk = true;
                if (selfSprite.parentGuid == this.sprites[i].guid) { isOk = false; }
                if ( isOk && requiredTypes != null && !requiredTypes.inArray(this.sprites[i].type) ) { isOk = false; }
                if ( isOk && collideWithChildren && this.sprites[i].parentGuid == selfSprite.guid ) { isOk = false; }
                if ( isOk ) {
                    var a = selfSprite.getPaddedRectangle();
                    var b = this.sprites[i].getPaddedRectangle();
                    var doesCollide = a.x1 <= b.x2 && a.x2 >= b.x1 && a.y1 <= b.y2 && a.y2 >= b.y1;
                    isOk = doesCollide;
                }
    
                if (isOk) { collidingSprite = this.sprites[i]; }
            }
        }
    }
    return collidingSprite;
}

App.prototype.getSpriteByGuid = function(guid) {
    var sprite = null;
    for (var i = 0; i < this.sprites.length && sprite == null; i++) {
        if (this.sprites[i].guid == guid) {
            sprite = this.sprites[i];
        }
    }
    return sprite;
}

App.prototype.getFrontMostWarriorSprite = function(gender) {
    var frontSprite = null;
    for (var i = 0; i < this.sprites.length; i++) {
        var sprite = this.sprites[i];
        if (sprite.type == Enum.typeWarrior && sprite.warrior.gender == gender) {
            var isFronter = gender == Enum.male ?
                    frontSprite == null || sprite.x > frontSprite.x : frontSprite == null || sprite.x < frontSprite.x;
            if (isFronter) { frontSprite = sprite; }
        }
    }
    return frontSprite;
}

App.prototype.getSpriteByParentGuid = function(parentGuid, optionalRequiredTypes) {
    optionalRequiredTypes = Misc.toArray(optionalRequiredTypes);
    var sprite = null;
    for (var i = 0; i < this.sprites.length && sprite == null; i++) {
        if (this.sprites[i].parentGuid == parentGuid) {
            var isOk = true;
            if ( isOk && optionalRequiredTypes != null && !optionalRequiredTypes.inArray(this.sprites[i].type) ) { isOk = false; }
            if (isOk) { sprite = this.sprites[i]; }
        }
    }
    return sprite;
}

App.prototype.addSound = function(enumSound) {
    if (enumSound != null) { this.soundsToPlay[this.soundsToPlay.length] = enumSound; }
}

App.prototype.playSounds = function() {
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

App.prototype.increaseActionEnergyOfOwnTeam = function(gender) {
    for (var i = 0; i < this.sprites.length; i++) {
        var sprite = this.sprites[i];
        if ( sprite.type == Enum.typeWarrior && sprite.warrior.gender == gender && sprite.warrior.role != Enum.roleMotivator ) {

            var semiPassivePhases = new Array(Enum.phaseStand, Enum.phaseWalk, Enum.phaseDefend);
            var passivePhases = new Array(Enum.phaseStand, Enum.phaseWalk);

            if ( semiPassivePhases.inArray(sprite.phase.name) ) {
                this.createEffect(Enum.heart, sprite.getCenter(), 0, -2, 20);
            }

            if ( passivePhases.inArray(sprite.phase.name) ) {
                var hasTapIcon = this.getSpriteByParentGuid(sprite.guid, Enum.typeTapIcon) != null;
                if (sprite.warrior.actionEnergy < sprite.warrior.actionEnergyNeeded && !hasTapIcon) {
                    sprite.warrior.actionEnergy = sprite.warrior.actionEnergyNeeded - 1;
                }
            }
        }
    }
}

App.prototype.getVerboseNumber = function(numberFrom0to10) {
    var verbose = new Array('zero','one','two','three','four','five','six','seven','eight','nine','ten');
    return Misc.isSet(verbose[numberFrom0to10]) ? verbose[numberFrom0to10] : null;
}

function App() {
    this.name = 'knights-vs-knightesses';
    this.version  = '1.0';
    var isIPad = navigator.userAgent.match(/iPad/i) != null;
    this.isLocalTest = !isIPad;
    // this.isLocalTest = false;

    this.showDebugInfo = true;
    this.showFramesPerSecond = false;

    this.intervalMS = 60;

    this.scoreMax = 10;
    this.eventFrequencyMedium = 25;
    this.eventFrequencyVariance = 5;
    this.eventFrequencySeconds = Misc.getRandomInt(
            this.eventFrequencyMedium - this.eventFrequencyVariance, this.eventFrequencyMedium + this.eventFrequencyVariance);

    this.clockSecondsMS = 1000;
    this.useAudioMethod = this.isLocalTest;
    this.debugElm = null;
    this.clickEventName = this.isLocalTest ? 'onclick' : 'ontouchstart';

    this.width = 1024;
    this.height = 768;
    this.playersMax = 2;

    this.score = new Array();
    this.scoreOld = new Array();
    this.scoreElm = new Array();
    this.warriorCreatedCount = new Object();
    this.warriorCreatedCount[Enum.male] = 0;
    this.warriorCreatedCount[Enum.female] = 0;

    for (var i = 0; i < this.playersMax; i++) {
        this.score[i] = 0;
        this.scoreOld[i] = null;
        this.scoreElm[i] = null;
    }

    this.fieldMinX = 0;
    this.fieldMaxX = this.width;
    this.fieldMinY = 0;
    this.fieldMaxY = this.height;

    this.debugCounter = 0;
    this.sprites = new Array();
    this.framesPerSecond = null;

    this.spriteName = new Object();
    this.spriteName[Enum.typeWarrior] = 'warrior';
    this.spriteName[Enum.typeWarriorGhost] = 'warrior';
    this.spriteName[Enum.typeTapIcon] = 'tap-icon';
    this.spriteName[Enum.typeOpenWindow] = 'open-window';
    this.spriteName[Enum.typeEagle] = 'eagle';
    this.spriteName[Enum.typeEaglePack] = 'eagle-pack';
    this.spriteName[Enum.typeEffect] = 'effect';

    this.spriteName[Enum.male] = 'male';
    this.spriteName[Enum.female] = 'female';

    this.spriteName[Enum.knife] = 'knife';
    this.spriteName[Enum.food] = 'food';
    this.spriteName[Enum.blood] = 'blood';
    this.spriteName[Enum.heart] = 'heart';

    this.spriteName[Enum.phaseStand] = 'stand';
    this.spriteName[Enum.phaseWalk] = 'walk';
    this.spriteName[Enum.phasePrepareAttack] = 'prepare-attack';
    this.spriteName[Enum.phaseAttack] = 'attack';
    this.spriteName[Enum.phaseShock] = 'shock';
    this.spriteName[Enum.phaseDefend] = 'defend';
    this.spriteName[Enum.phaseMotivate] = 'motivate';
    this.spriteName[Enum.phaseGhost] = 'ghost';
    this.spriteName[Enum.phaseFollowTarget] = 'follow-target';
    this.spriteName[Enum.phaseFollowTargetThenAttack] = 'follow-target-then-attack';

    this.spriteName[Enum.maleKnight] = 'male-knight';
    this.spriteName[Enum.maleArcher] = 'male-archer';
    this.spriteName[Enum.maleShieldbearer] = 'male-shieldbearer';
    this.spriteName[Enum.maleDrummer] = 'male-drummer';
    this.spriteName[Enum.maleBerserker] = 'male-berserker';
    this.spriteName[Enum.maleWizard] = 'male-wizard';
    this.spriteName[Enum.maleUnibird] = 'male-unibird';

    this.spriteName[Enum.femaleKnight] = 'female-knight';
    this.spriteName[Enum.femaleArcher] = 'female-archer';
    this.spriteName[Enum.femaleShieldbearer] = 'female-shieldbearer';
    this.spriteName[Enum.femaleFlagbearer] = 'female-flagbearer';
    this.spriteName[Enum.femaleBerserker] = 'female-berserker';
    this.spriteName[Enum.femaleWizard] = 'female-wizard';
    this.spriteName[Enum.femaleUnibird] = 'female-unibird';

    this.soundsToPlay = new Array();

    this.soundName = new Array();
    this.soundName[Enum.soundWinner] = 'winner';

    this.soundIsImportant = new Array();
    this.soundIsImportant[Enum.soundWinner] = true;

    this.maxSoundsSameAtOnce = 3;
    this.soundCache = new Object();
    this.speedFactor = 1;

    this.winningPlayer = null;

    this.secondsCounter = 0;
    this.minutesCounter = 0;

    this.soundPlayEnergyNeeded = 2;
    this.soundPlayEnergy = 0;

    this.intervalId = null;
    this.intervalIdSeconds = null;

    this.spriteSize = new Object();
    this.spriteSize[Enum.typeWarrior] = new Size(235, 145);
    this.spriteSize[Enum.typeWarriorGhost] = this.spriteSize[Enum.typeWarrior];
    this.spriteSize[Enum.typeTapIcon] = new Size(50, 100);

    this.FPSMax = Misc.roundNumber(1000 / this.intervalMS);

    this.defaultDamageCausedPerAttack = 4;

    var windowPos = new Object();
    windowPos[Enum.maleDrummer] = new Position(131,138);
    windowPos[Enum.maleUnibird] = new Position(215,133);
    windowPos[Enum.maleWizard] = new Position(118,237);
    windowPos[Enum.maleBerserker] = new Position(175,231);
    windowPos[Enum.maleShieldbearer] = new Position(229,233);
    windowPos[Enum.maleArcher] = new Position(138,356);
    windowPos[Enum.maleKnight] = new Position(203,350);
    windowPos[Enum.femaleUnibird] = new Position(760,135);
    windowPos[Enum.femaleFlagbearer] = new Position(843,138);
    windowPos[Enum.fermaleShieldbearer] = new Position(744,235);
    windowPos[Enum.femaleBerserker] = new Position(804,232);
    windowPos[Enum.femaleWizard] = new Position(862,237);
    windowPos[Enum.femaleKnight] = new Position(777,350);
    windowPos[Enum.femaleArcher] = new Position(848,356);

    this.newsDialog = new NewsDialog();
}
