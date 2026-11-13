local AudioManager = {}
AudioManager.__index = AudioManager

function AudioManager.new(config)
    config = config or {}

    assert(config.resourceManager, "resourceManager is required")

    local self = setmetatable({}, AudioManager)

    self.resourceManager = config.resourceManager

    self.masterVolume = config.masterVolume
    self.musicVolume = config.musicVolume
    self.sfxVolume = config.sfxVolume

    self.currentMusic = nil
    self.activeSounds = {}
    self.nextSoundId = 0

    return self
end

function AudioManager:playMusic(resourceId, config)
    config = config or {}

    local source = self.resourceManager:get(self, resourceId)

    if self.currentMusic and self.currentMusic.id == resourceId then
        if self.currentMusic.paused then
            self:resumeMusic()
        end

        return
    end

    if self.currentMusic then
        self:stopMusic()
    end

    local loop = config.loop == true

    source:setLooping(loop)
    source:setVolume(self.masterVolume * self.musicVolume)
    source:play()

    self.currentMusic = {
        id = resourceId,
        source = source,
        loop = loop,
        paused = false
    }
end

function AudioManager:playSound(resourceId)
    local source = self.resourceManager:get(self, resourceId)
    local instance = source:clone()

    self.nextSoundId = self.nextSoundId + 1
    local soundId = self.nextSoundId

    instance:setVolume(self.masterVolume * self.sfxVolume)
    instance:play()

    self.activeSounds[soundId] = {
        id = resourceId,
        source = instance,
        paused = false
    }

    return soundId
end

function AudioManager:stopMusic()
    if not self.currentMusic then
        return
    end

    self.currentMusic.source:stop()
    self.currentMusic = nil
end

function AudioManager:stopSound(soundId)
    local sound = self.activeSounds[soundId]

    if not sound then
        return
    end

    sound.source:stop()
    sound.source:release()

    self.activeSounds[soundId] = nil
end

function AudioManager:pauseMusic()
    if not self.currentMusic or self.currentMusic.paused then
        return
    end

    self.currentMusic.source:pause()
    self.currentMusic.paused = true
end

function AudioManager:resumeMusic()
    if not self.currentMusic or not self.currentMusic.paused then
        return
    end

    self.currentMusic.source:play()
    self.currentMusic.paused = false
end

function AudioManager:isMusicPlaying()
    return self.currentMusic ~= nil
        and not self.currentMusic.paused
        and self.currentMusic.source:isPlaying()
end

function AudioManager:isSoundPlaying(soundId)
    local sound = self.activeSounds[soundId]

    if not sound then
        return false
    end

    return not sound.paused and sound.source:isPlaying()
end

function AudioManager:isMusicPaused()
    return self.currentMusic ~= nil
        and self.currentMusic.paused
end

function AudioManager:getCurrentMusic()
    if not self.currentMusic then
        return nil
    end

    return self.currentMusic.id
end


function AudioManager:update(dt)
    for soundId, sound in pairs(self.activeSounds) do
        if not sound.source:isPlaying() and not sound.paused then
            sound.source:release()
            self.activeSounds[soundId] = nil
        end
    end
end

function AudioManager:shutdown()
    self:stopMusic()

    for soundId, sound in pairs(self.activeSounds) do
        sound.source:stop()
        sound.source:release()
        self.activeSounds[soundId] = nil
    end

    self.resourceManager:releaseAll(self)
end

return AudioManager
