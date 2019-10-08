module(..., package.seeall)

function dragBody(event, params)
    local self = event.target
    local phase = event.phase
    local stage = display.getCurrentStage()

    if phase == 'began' then
        self.data.bodyTypeOld = self.bodyType
        self.bodyType = 'dynamic'
        stage:setFocus(self, event.id)
        self.data.isFocus = true
        self.tempJoint = physics.newJoint('touch', self, event.x, event.y)

    elseif self.data.isFocus then
        if phase == 'moved' then
            self.tempJoint:setTarget(event.x, event.y)

        elseif phase == 'ended' or phase == 'cancelled' then
            stage:setFocus(self, nil)
            self.data.isFocus = false
            self.tempJoint:removeSelf()
            self.bodyType = self.data.bodyTypeOld
        end
    end

    local cancelPropagation = true
    return cancelPropagation
end
