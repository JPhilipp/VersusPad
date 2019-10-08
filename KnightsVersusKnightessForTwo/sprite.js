Sprite.prototype.handleTypeSpecificBehavior = function() {
    switch ( parseInt(this.type) ) {
        case Enum.typeWarrior: this.handleWarrior(); break;
        case Enum.typeDamageWave: this.handleDamageWave(); break;
    }
}


Sprite.prototype.handleDamageWave = function() {
    var collidedSprite = app.getCollidingSprite(this);
    if (collidedSprite != null) {
        collidedSprite.damageEnergyReceived += app.defaultDamageCausedPerAttack;
        collidedSprite.damageEnergyReceivedDirection = new Vector(this.directionX, this.directionY);
        this.gone = true;
    }
}

Sprite.prototype.handleWarrior = function() {
    if (this.warrior.doAct) {
        this.warrior.doAct = false;
        switch (this.warrior.role) {
            case Enum.roleHitter:
            case Enum.roleDefender:
                var frontSprite = app.getFrontMostWarriorSprite(this.warrior.gender);
                if (frontSprite == this) {
                    if (this.warrior.role == Enum.roleDefender) {
                        this.phase = new Phase(Enum.phaseDefend);
                    }
                    else {
                        this.phase = new Phase(Enum.phasePrepareAttack);
                    }
                }
                else {
                    this.startSwitchPositionWithFrontSprite(frontSprite);
                }
                break;

            case Enum.roleMotivator:
                this.phase = new Phase(Enum.phaseMotivate);
                break;

            case Enum.roleShooter:
                break;
        }
    }

    this.handleWarriorReceiveDamage();

    switch (this.phase.name) {
        case Enum.phaseStand:
            if ( !this.phase.getInitedAndInit() ) {
                this.cellsMax = 1;
                if (this.warrior.actionEnergySpeed == 0) { this.warrior.actionEnergySpeed = 1; }
                this.phase.setCounterForNext( 60 + Misc.getRandomInt(0, 30), Enum.phaseWalk );
            }
            break;

        case Enum.phaseWalk:
            if ( !this.phase.getInitedAndInit() ) {
                this.cellsMax = 1;
                var didCollide = false;
                var walkedABit = false;
                for (var i = 1; i < this.stepWidth && !didCollide; i++) {
                    this.x += this.directionX;
                    didCollide = app.getCollidingSprite(this) != null;
                    if (didCollide) {
                        this.x += this.directionX * -1;
                    }
                    else {
                        walkedABit = true;
                    }
                }

                if (walkedABit) {
                    this.phase.setCounterForNext(10, Enum.phaseStand);
                }
                else {
                    this.phase = new Phase(Enum.phaseStand);
                }
            }
            break;

        case Enum.phasePrepareAttack:
            if ( !this.phase.getInitedAndInit() ) {
                this.phase.setCounterForNext(15, Enum.phaseAttack);
            }
            break;

        case Enum.phaseAttack:
            if ( !this.phase.getInitedAndInit() ) {
                this.phase.setCounterForNext(12, Enum.phaseStand);
                app.createDamageWave( this.getCenter(), this.guid, this.directionX * 20, 0 );
            }
            break;

        case Enum.phaseDefend:
            if ( !this.phase.getInitedAndInit() ) {
                this.phase.setCounterForNext(200, Enum.phaseStand);
                this.warrior.actionEnergySpeed = 0;
            }
            break;

        case Enum.phaseShock:
            if ( !this.phase.getInitedAndInit() ) {
                this.removeWarriorTapIconTemporarily(16);
                this.phase.setCounterForNext(15, Enum.phaseStand);
            }
            break;

        case Enum.phaseFollowTarget:
        case Enum.phaseFollowTargetThenAct:
            if ( !this.phase.getInitedAndInit() ) {
            }

            if (++this.warrior.changePlaceCounter == 4) {
                this.appearance = this.appearance != app.spriteName[Enum.phaseWalk] ? app.spriteName[Enum.phaseWalk] : app.spriteName[Enum.phaseStand];
                this.warrior.changePlaceCounter = 0;
            }

            if ( this.foundTargetWhileFollowing() ) {
                this.targetX = null;
                this.targetY = null;
                app.removeSpriteByParentGuid(Enum.typePlaceholder, this.guid);

                if (this.phase.name == Enum.phaseFollowTargetThenAct) {
                    if (this.warrior.role == Enum.roleHitter) {
                        this.phase = new Phase(Enum.phasePrepareAttack);
                    }
                    else {
                        this.phase = new Phase(Enum.phaseDefend);
                    }
                }
                else {
                    this.warrior.actionEnergySpeed = 1;
                    this.phase = new Phase(Enum.phaseStand);
                }
            }
            break;

        case Enum.phaseMotivate:
            if ( !this.phase.getInitedAndInit() ) {
                this.cellsMax = 2;
                this.cellsSpeed = .2;
                this.phase.setCounterForNext(60, Enum.phaseStand);
                app.increaseActionEnergyOfOwnTeam(this.warrior.gender);
                this.actionEnergySpeed = 0;
            }

            if (this.phase.counter == 15) {
                app.increaseActionEnergyOfOwnTeam(this.gender);
            }
            break;
    }

    this.warrior.handleTapIcon( this.guid, this.getCenter() );

    if (this.debugMe) {
        // app.debug('energy = ' + this.energy);
        // app.debug( this.phase.getInfo() );
        app.debug('actionEnergy = ' + this.warrior.actionEnergy + ' / ' + this.warrior.actionEnergyNeeded + '<br/>' +
                'actionEnergySpeed = ' + this.warrior.actionEnergySpeed);
    }
}

Sprite.prototype.handleWarriorReceiveDamage = function() {
    if (this.damageEnergyReceived != 0) {
        if ( !(this.phase.name == Enum.phaseDefend) ) {
            this.energy -= this.damageEnergyReceived;

            var bloodEnergy = this.energy <= 0 ? 25 : 10;
            app.createEffect( Enum.blood, this.getCenter(), this.damageEnergyReceivedDirection.x * 2, -.75, bloodEnergy );
            this.phase = new Phase(Enum.phaseShock);
            this.warrior.actionEnergy -= 40;
            if (this.warrior.actionEnergy < 0) { this.warrior.actionEnergy = 0; }

            if (this.energy <= 0) {
                app.createWarriorGhost(this.subtype, this.x, this.y, this.damageEnergyReceivedDirection.x * 2, -4);
            }
        }

        this.damageEnergyReceived = 0;
        this.damageEnergyReceivedDirection = null;
    }
}

Sprite.prototype.startSwitchPositionWithFrontSprite = function(frontSprite) {
    app.createPlaceholder( this.guid, this.getPaddedRectangle() );
    app.createPlaceholder( frontSprite.guid, frontSprite.getPaddedRectangle() );
    
    this.targetX = frontSprite.x;
    this.targetY = null;
    this.warrior.actionEnergy -= 5;
    if (this.warrior.actionEnergy < 0) { this.warrior.actionEnergy = 0; }
    this.warrior.actionEnergySpeed = 0;
    this.removeTapIcon();
    this.phase = new Phase(Enum.phaseFollowTargetThenAct);
    this.warrior.changePlaceCounter = 0;
    
    frontSprite.targetX = this.x;
    frontSprite.targetY = null;
    frontSprite.warrior.actionEnergy -= 5;
    if (frontSprite.warrior.actionEnergy < 0) { frontSprite.warrior.actionEnergy = 0; }
    frontSprite.warrior.actionEnergySpeed = 0;
    frontSprite.removeTapIcon();
    frontSprite.phase = new Phase(Enum.phaseFollowTarget);
    frontSprite.warrior.changePlaceCounter = 0;
}

Sprite.prototype.foundTargetWhileFollowing = function() {
    if (this.targetX != null) {
        if (this.x < this.targetX) {
            this.x += this.stepWidth / 2;
            if (this.x > this.targetX) { this.x = this.targetX; }
        }
        else if (this.x > this.targetX) {
            this.x -= this.stepWidth / 2;
            if (this.x < this.targetX) { this.x = this.targetX; }
        }
    }

    if (this.targetY != null) {
        if (this.y < this.targetY) {
            this.y += this.stepWidth / 2;
            if (this.y > this.targetY) { this.y = this.targetY; }
        }
        else if (this.y > this.targetY) {
            this.y -= this.stepWidth / 2;
            if (this.y < this.targetY) { this.y = this.targetY; }
        }
    }

    var foundX = this.targetX == null || this.x == this.targetX;
    var foundY = this.targetY == null || this.y == this.targetY;
    return foundX && foundY;
}

Sprite.prototype.doesCollide = function() {
}

Sprite.prototype.handleCollision = function() {
    for (var i = 0; i < app.sprites.length && !this.didCollide; i++) {
        var other = app.sprites[i];
        if (this.guid != other.guid) {
            if ( this.doesCollide(other) ) {
                /*
                switch (other.type) {
                }
                */
            }
        }
    }
}

Sprite.prototype.dieOutsideField = function() {
    if (this.x + this.width < app.fieldMinX || this.x > app.fieldMaxX ||
            this.y + this.height < app.fieldMinY || this.y > app.fieldMaxY) {
        this.gone = true;
    }
}

Sprite.prototype.stop = function() {
    this.speed.x = 0;
    this.speed.y = 0;
}

Sprite.prototype.getCenter = function() {
    return new Position(
            parseInt( this.x + (this.width / 2) ),
            parseInt( this.y + (this.height / 2) ) );
}

Sprite.prototype.handleGenericBehavior = function() {
    this.handleGravity();
    this.lastPos.x = this.x;
    this.lastPos.y = this.y;
    this.x += this.speed.x;
    this.y += this.speed.y;

    if (this.speedDeterminesDirection) { this.setDirectionBySpeed(this.speed, true); }

    if (!this.inited) {
        this.speed.x *= app.speedFactor; // Math.sqrt
        this.speed.y *= app.speedFactor;
        this.cellsSpeed *= app.speedFactor;

        if (this.cellsMax > 1) {
            this.cell = 1; // + Misc.getRandomInt(1, 9) / 10;
        }
        this.energyOld = this.energy;
        this.inited = true;
    }

    if (this.cell > this.cellsMax) { this.cell = 1; }

    this.followTargetSpeed();
    if (this.phase != null) {
        this.phase.handleCounter();
        if ( this.phasesWithOwnAppearance.inArray(this.phase.name) ) {
            if (this.phase.inited) {
                if (this.appearance != app.spriteName[this.phase.name]) {
                    this.cell = 1;
                    this.appearance = app.spriteName[this.phase.name]; // hmm, called every frame... perhaps tie tighter to counter.
                }
            }
        }
    }

    if (this.energySpeed != null) { this.energy += this.energySpeed; }
    this.didCollide = false;

    this.moveCell();
    this.energyOld = this.energy;
}

Sprite.prototype.handleGravity = function() {
    if (this.reactsToGravity) { this.speed.y += .5; }
}

Sprite.prototype.setDirectionBySpeed = function(speed, useLastDirectionIfStops) {
    var newDirectionX = 0;
    var newDirectionY = 0;

    var angle = speed.getAngle();

    if (angle <= -67.5 && angle >= -112.5) {
        newDirectionX = 0;
        newDirectionY = -1;
    }
    else if (angle >= -157.5 && angle >= 157.5) {
        newDirectionX = -1;
        newDirectionY = 0;
    }
    else if (angle <= 157.5 && angle >= 112.5) {
        newDirectionX = -1;
        newDirectionY = 1;
    }
    else if (angle <= 112.5 && angle >= 67.5) {
        newDirectionX = 0;
        newDirectionY = 1;
    }
    else if (angle <= 67.5 && angle >= 22.5) {
        newDirectionX = 1;
        newDirectionY = 1;
    }
    else if (angle <= 22.5 && angle >= -22.5) {
        newDirectionX = 1;
        newDirectionY = 0;
    }
    else if (angle <= -22.5 && angle >= -67.5) {
        newDirectionX = 1;
        newDirectionY = -1;
    }
    else {
        newDirectionX = -1;
        newDirectionY = -1;
    }

    this.directionX = newDirectionX;
    this.directionY = newDirectionY;
}

Sprite.prototype.followTargetSpeed = function() {
    if (this.targetSpeed.x != null && this.targetSpeed.y != null &&
            (this.targetSpeed.x != this.speed.x || this.targetSpeed.y != this.speed.y) ) {
        var xdiff = this.targetSpeed.x - this.speed.x;
        var ydiff = this.targetSpeed.y - this.speed.y;
        var angle = Math.atan2(ydiff, xdiff);
        this.speed.x += this.speedStep * Math.cos(angle);
        this.speed.y += this.speedStep * Math.sin(angle);
        var fuzzy = .5;
        if ( Math.abs(this.speed.x) - Math.abs(this.targetSpeed.x) < fuzzy) {
            this.speed.x = this.targetSpeed.x;
        }
        if ( Math.abs(this.speed.y) - Math.abs(this.targetSpeed.y) < fuzzy) {
            this.speed.y = this.targetSpeed.y;
        }
    }
}

Sprite.prototype.handleMoveChildWithParent = function() {
    if (this.movesWithParent) {
        var parentSprite = app.getSpriteByGuid(this.parentGuid);
        if ( Misc.isSet(parentSprite) && (parentSprite.x != parentSprite.xOld || parentSprite.y != parentSprite.yOld) &&
                !(parentSprite.xOld == null || parentSprite.yOld == null ) ) {
            var offX = parentSprite.xOld - parentSprite.x;
            var offY = parentSprite.yOld - parentSprite.y;
            this.x += offX *= -1;
            this.y += offY *= -1;
        }
    }
}

Sprite.prototype.getPos = function() {
    return new Position(this.x, this.y);
}

Sprite.prototype.moveCell = function() {
    if (this.cellsMax > 1) {
        var padding = .4;
        this.cell += this.cellsSpeed * 1;
        if (this.cell > this.cellsMax + padding) { this.cell = 1; }
    }
}

Sprite.prototype.createImage = function() {
    var appearance = app.spriteName[this.type];
    if (this.subtype != null) { appearance += '/' + app.spriteName[this.subtype]; }
    if (this.appearance != null) { appearance += '/' + this.appearance; }
    if (this.directionDeterminesAppearance) { appearance += '_x' + this.directionX + '_y' + this.directionY; }

    this.elm = document.createElement('div');
    this.elm.setAttribute('class', 'sprite');
    this.elm.style.width = this.width + 'px';
    this.elm.style.height = this.height + 'px';
    this.elm.style.zIndex = this.zIndex;
    if (this.imagePosPercent != null) {
        this.elm.style.backgroundPosition = this.imagePosPercent.x + '% ' + this.imagePosPercent.y + '%';
    }

    if (this.type == Enum.typeRectangle) {
        this.elm.style.border = '4px dashed red';
        this.elm.style.borderRadius = '12px';
    }

    // xxx if (this.type == Enum.typeEffect) { app.debugAndStop(appearance); }
    if (this.hasImage) {
        this.elm.style.backgroundImage = 'url(image/' + appearance + '.png)';
        // this.elm.className = appearance;
    }

    if (this.clickEvent != null) { this.elm.setAttribute(app.clickEventName, this.clickEvent); }
    if (this.dragStartEvent != null) { this.elm.setAttribute(app.dragStartEventName, this.dragStartEvent); }
    if (this.dragMoveEvent != null) { this.elm.setAttribute(app.dragMoveEventName, this.dragMoveEvent); }
    if (this.dragEndEvent != null) { this.elm.setAttribute(app.dragEndEventName, this.dragEndEvent); }

    document.body.appendChild(this.elm);
}

Sprite.prototype.changeImage = function(cellRounded) {
    var appearance = app.spriteName[this.type];
    if (this.subtype != null) { appearance += '/' + app.spriteName[this.subtype]; }
    if (this.appearance != null) { appearance += '/' + this.appearance; }
    if (this.directionDeterminesAppearance) { appearance += '_x' + this.directionX + '_y' + this.directionY; }
    if (cellRounded > 1) { appearance += '_c' + cellRounded; }

    // if (this.type == Enum.typeController) { app.debugAndStop(appearance); }
    if (this.hasImage) {
        this.elm.style.backgroundImage = 'url(image/' + appearance + '.png)';
        // this.elm.className = appearance;
    }

    this.directionXOld = this.directionX;
    this.directionYOld = this.directionY;
    this.cellRoundedOld = cellRounded;
}

Sprite.prototype.getRectangle = function() {
    return new Rectangle(this.x, this.y, this.x + this.width, this.y + this.height);
}

Sprite.prototype.getPaddedRectangle = function() {
    var rectangle = new Rectangle(this.x, this.y, this.x + this.width, this.y + this.height)
    rectangle.subtract(this.padding);
    return rectangle;
}

Sprite.prototype.showDebugRect = function() {
    var rect = new Rectangle();
    rect.setToRect( this.getRectangle() );
    rect.show(0, 0);
    app.debug( 'Rect = ' + rect.getInfo() );
}

Sprite.prototype.setSizeBasedOnType = function() {
    this.width = app.spriteSize[this.type].width;
    this.height = app.spriteSize[this.type].height;
}

Sprite.prototype.setPosByCenter = function(centerPos) {
    this.x = parseInt(centerPos.x - this.width / 2);
    this.y = parseInt(centerPos.y - this.height / 2);
}

Sprite.prototype.show = function() {
    if (!this.elmInited) {
        this.createImage();
        this.elmInited = true;
    }

    var imageChanged = false;
    var cellRounded = Math.round(this.cell);
    if ( cellRounded != this.cellRoundedOld ||
            this.appearance != this.appearanceOld ||
            this.directionX != this.directionXOld || this.directionY != this.directionYOld
            || this.subtype != this.subtypeOld ) {
        this.changeImage(cellRounded);
        imageChanged = true;
        this.subtypeOld = this.subtype;
        this.appearanceOld = this.appearance;
    }

    var xInt = parseInt(this.x);
    if (xInt != this.xOld) {
        this.elm.style.left = xInt + 'px';
        this.xOld = xInt;
    }
    var yInt = parseInt(this.y);
    if (yInt != this.yOld) {
        this.elm.style.top = yInt + 'px';
        this.yOld = yInt;
    }
}

Sprite.prototype.removeTapIcon = function() {
    var tapIcon = app.getSpriteByParentGuid(this.guid, Enum.typeTapIcon);
    if (tapIcon != null) { tapIcon.gone = true; }
}

Sprite.prototype.removeWarriorTapIconTemporarily = function(howLong) {
    var tapIcon = app.getSpriteByParentGuid(this.guid, Enum.typeTapIcon);
    if (tapIcon != null) {
        tapIcon.gone = true;
        this.warrior.actionEnergy -= howLong;
        this.warrior.actionEnergySpeed = 1;
    }
}

function Sprite() {
    this.guid = 'id' + Misc.getRandomString(16);
    this.x = 0;
    this.y = 0;
    this.xOld = null;
    this.yOld = null;
    this.width = null;
    this.height = null;

    this.speed = new Vector();
    this.targetSpeed = new Vector();
    this.targetSpeed.x = null;
    this.targetSpeed.y = null;
    this.speedMax = 5;
    this.speedStep = 1;
    this.stepWidth = 30;

    this.energyMax = 100;
    this.energy = this.energyMax;
    this.energyOld = this.energy;
    this.energySpeed = null;
    this.directionX = 0;
    this.directionY = 0;
    this.speedDeterminesDirection = true;
    this.directionDeterminesAppearance = true;
    this.gone = false;

    this.clickEvent = null;

    this.parentGuid = null;
    this.appearance = null;

    this.cell = 1;
    this.cellsSpeed = .08;
    this.cellsMax = 1;

    this.type = null;
    this.subtype = null;
    this.subtypeOld = null;
    this.appearance = null;
    this.appearanceOld = null;
    this.imagePosPercent = null;
    this.phase = null;

    this.directionXOld = null;
    this.directionYOld = null;
    this.cellRoundedOld = null;

    this.elm = null;
    this.elmInited = false;
    this.hasImage = true;
    this.inited = false;
    this.zIndex = 100;
    this.padding = new Padding();
    this.damageEnergyReceived = 0;
    this.damageEnergyReceivedDirection = null;

    this.disappearsWithParent = false;
    this.movesWithParent = false;

    this.didCollide = false;
    this.isCollidable = true;
    this.phasesWithOwnAppearance = new Array();
    this.canCollide = true;
    this.reactsToGravity = false;

    this.lastPos = new Position(this.x, this.y);
}

/***********/


Warrior.prototype.getEnergyAfterAttack = function(selfEnergy, attackStrength) {
    var fuzzinessOfAttacks = 1;
    attackStrength = Misc.forceMin(attackStrength - this.defense, 0);
    selfEnergy -= ( attackStrength + Misc.getRandomInt(-fuzzinessOfAttacks, fuzzinessOfAttacks) );
    return selfEnergy;
}

Warrior.prototype.handleTapIcon = function(guid, centerPos) {
    var doCreateIcon = false;

    if (this.actionEnergySpeed != 0) {
        this.actionEnergy += this.actionEnergySpeed;
        if (this.actionEnergy >= this.actionEnergyNeeded) {
            this.actionEnergySpeed = 0;
            this.actionEnergy = this.actionEnergyNeeded;
            doCreateIcon = true;
        }
    }

    if (this.actionEnergy > this.actionEnergyNeeded) {
        this.actionEnergy = this.actionEnergyNeeded;
        doCreateIcon = true;
    }

    if ( doCreateIcon && app.getSpriteByParentGuid(guid, Enum.typeTapIcon) == null ) {
        app.createTapIcon(guid, this.gender, centerPos);
    }
}

Warrior.prototype.initByType = function() {
    switch (this.type) {
        case Enum.maleKnight:
        case Enum.femaleKnight:
            this.castEnergyNeeded = 100;
            this.relativeWindowNumber = 5;
            this.actionsInRow = 1;
            this.role = Enum.roleHitter;
            break;

        case Enum.maleBerserker:
        case Enum.femaleBerserker:
            this.castEnergyNeeded = 200;
            this.relativeWindowNumber = 3;
            this.actionsInRow = 2;
            this.role = Enum.roleHitter;
            break;

        case Enum.maleArcher:
        case Enum.femaleArcher:
            this.castEnergyNeeded = 100;
            this.relativeWindowNumber = 6;
            this.actionsInRow = 1;
            this.role = Enum.roleShooter;
            break;

        case Enum.maleWizard:
        case Enum.femaleWizard:
            this.castEnergyNeeded = 200;
            this.relativeWindowNumber = 4;
            this.actionsInRow = 2;
            this.role = Enum.roleShooter;
            break;

        case Enum.maleUnibird:
        case Enum.femaleUnibird:
            this.castEnergyNeeded = 300;
            this.relativeWindowNumber = 0;
            this.actionsInRow = 1;
            this.role = Enum.roleHitter;
            break;

        case Enum.maleShieldbearer:
        case Enum.femaleShieldbearer:
            this.castEnergyNeeded = 200;
            this.relativeWindowNumber = 2;
            this.actionsInRow = 1;
            this.role = Enum.roleDefender;
            break;

        case Enum.maleDrummer:
        case Enum.femaleFlagbearer:
            this.castEnergyNeeded = 300;
            this.relativeWindowNumber = 1;
            this.actionsInRow = 1;
            this.role = Enum.roleMotivator;
            this.actionEnergyNeeded = 380;
            break;
    }

    this.place = this.type == Enum.maleUnibird || this.type == Enum.femaleUnibird ?  Enum.air : Enum.ground;
}

function Warrior(gender, type, debugMe) {
    this.gender = gender;
    this.type = type;
    this.castEnergyNeeded = 10;
    this.core = new Position();
    this.role = null;
    this.relativeWindowNumber = null;
    this.place = Enum.ground;
    this.debugMe = Misc.isSet(debugMe) ? debugMe : false;
    this.doAct = false;
    this.changePlaceCounter = 0;

    this.actionEnergyNeeded = 180; // 220
    this.actionEnergySpeed = 1;
    this.actionsInRow = 1;

    this.isShooter = false;
    this.shotEnergy = 0;

    this.initByType();
    this.actionEnergy = this.actionEnergyNeeded - 15;
}
