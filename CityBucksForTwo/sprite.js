Sprite.prototype.handleTypeSpecificBehavior = function(spriteNumber) {
    switch ( parseInt(this.type) ) {

        case app.enumSpriteCafe:
            if (!this.inited) {
                this.speedY = 0;
                this.energy = 5;
            }
            break;

        case app.enumSpriteHuman:
            if (!this.inited) {
                this.speedY = 0;
                this.energy = 5;
            }
            break;
    }
}

Sprite.prototype.getCenter = function() { 
    return {
        x: this.x + (this.width / 2), 
        y: this.y + (this.height / 2) 
    }; 
};

Sprite.prototype.getSpeed = function() { 
    return {
        x: this.speedX,
        y: this.speedY 
    }; 
};

Sprite.prototype.handleGenericBehavior = function(spriteNumber) {
    this.phaseInited = true;

    this.x += this.speedX;
    this.y += this.speedY;
    if (this.speedDeterminesDirection) {
        this.directionX = app.getDirection(this.speedX);
        this.directionY = app.getDirection(this.speedY);
    }

    if (!this.inited) {
        this.speedX *= Math.sqrt(app.speedFactor); // ...
        this.speedY *= Math.sqrt(app.speedFactor);
        this.cellsSpeed *= app.speedFactor;

        if (!app.spritesAreAnimated) { this.cellsMax = 1; }
        if (this.cellsMax > 1) { this.cell = 1 + Misc.getRandomInt(1, 9) / 10; }
        this.energyOld = this.energy;
        this.inited = true;
    }

    if (this.phase != null) {
        this.phaseCounter--;
        if (this.phaseCounter <= 0) {
            this.phaseCounter = 0;
            this.phaseInited = false;
            this.phase = this.phaseNext;
        }
    }

    if (this.energySpeed != null) { this.energy += this.energySpeed; }

    this.moveCell();
    this.keepInOwnLimits();

    this.energyOld = this.energy;

    if (this.minX == null) {
        if (this.x < app.fieldMinX) {
            this.speedX *= -1;
            this.x = app.fieldMinX;
        }
        else if (this.x > app.fieldMaxX - this.width) {
            this.speedX *= -1;
            this.x = app.fieldMaxX - this.width;
        }
    }

    this.events = new Object();
}

Sprite.prototype.keepInOwnLimits = function() {
    if (this.minX != null && this.x < this.minX) {
        this.speedX = Math.abs(this.speedX);
        this.x = this.minX;
    }
    if (this.maxX != null && this.x + this.width > this.maxX) {
        this.speedX = -Math.abs(this.speedX);
        this.x = this.maxX - this.width - 1;
    }

    if (this.minY != null && this.y < this.minY) {
        this.speedY = Math.abs(this.speedY);
        this.y = this.minY;
    }
    if (this.maxY != null && this.y + this.height > this.maxY) {
        this.speedY = -Math.abs(this.speedY);
        this.y = this.maxY - this.height - 1;
    }
}

Sprite.prototype.isOutsideField = function() {
    return this.x < app.fieldMinX || this.x + this.width > app.fieldMaxX ||
        this.y < app.fieldMinY || this.y + this.height > app.fieldMaxY;
}

Sprite.prototype.getDirectionAppearanceX = function() {
    return this.directionDeterminesAppearance ? this.directionX : 'Any';
}

Sprite.prototype.getDirectionAppearanceY = function() {
    return this.directionDeterminesAppearance ? this.directionY : 'Any';
}

Sprite.prototype.moveCell = function() {
    if (this.cellsMax > 1) {
        var padding = .4;
        this.cell += this.cellsSpeed * 1;
        if (this.cell > this.cellsMax + padding) { this.cell = 1; }
    }
}

Sprite.prototype.createSpriteImage = function(appearance) {
    this.elm = document.createElement('div');
    this.elm.setAttribute('class', 'sprite ' + appearance);
    this.elm.style.width = this.width + 'px';
    this.elm.style.height = this.height + 'px';
    this.elm.setAttribute( 'ontouchmove', 'g_preventDragging(event)' );
    if (this.clickEvent != null) { this.elm.setAttribute(app.clickEventName, this.clickEvent); }
    document.body.appendChild(this.elm);
}

function Sprite() {
    this.x = 0;
    this.y = 0;
    this.xOld = null;
    this.yOld = null;
    this.width = null;
    this.height = null;
    this.speedX = 0;
    this.speedY = 0;
    this.energy = 100;
    this.energyOld = this.energy;
    this.energySpeed = null;
    this.directionX = 0;
    this.directionY = 0;
    this.speedDeterminesDirection = true;
    this.directionDeterminesAppearance = true;
    this.gone = false;
    this.events = new Object();
    this.guid = 'id' + Misc.getRandomString(16);
    this.parentGuid = null;
    this.parentPlayer = null;

    this.minX = null;
    this.maxX = null;
    this.minY = null;
    this.maxY = null;

    this.clickEvent = null;

    this.cell = 1;
    this.cellsSpeed = .08;
    this.cellsMax = 2;

    this.type = null;
    this.phase = null;
    this.phaseCounter = 100;
    this.phaseInited = false;
    this.phaseNext = null;
    this.data = new Object();

    this.directionXOld = null;
    this.directionYOld = null;
    this.cellRoundedOld = null;

    this.elm = null;
    this.inited = false;
}
