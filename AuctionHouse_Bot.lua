-- Credits Mithras, Niam5, and ReynoldsCahoon --

-- Remastered by Jacatinelord / Sinmeowgra For Image API --
-- EMOJI ID Tutorial --
-- To add, go to your server settings -> emoji -> add 3 emojis to represent gold/silver/copper
-- Once added, in any channel type your emoji preceded by a backslash \ i.e. "\:gold:" -- This will give you the emoji id, which you place in these values i.e. "<:gold:1209645132832575578>"
-- END OF EMOJI ID Tutorial --

-- TODO: Include a proper JSON library
local auctionConfig = {
    auctionWebhookURL = "", -- Your Discord channel webhook url
    goldEmojiID = "", -- Your gold/silver/copper emojis
    silverEmojiID = "",
    copperEmojiID = "", 
    itemLinkDB = "https://wowgaming.altervista.org/aowow/", -- Your own AoWoW instance, or wowhead i.e. "https://www.wowhead.com/wotlk/"
    thumbnailIcons = true, -- Set to false if you don't have DBC data in your database and wish to forego icon thumbnails
    itemIconDB = "https://wowgaming.altervista.org/aowow/static/images/wow/icons/large/", -- A web-accessible directory of all icon images, or wowhead i.e. "https://wow.zamimg.com/images/wow/icons/large/"    -- The profile picture of the bot that posts in Discord
    itemQuality = {
        [0] = {
            color = 10329501,
            name = "Poor"
        },
        [1] = {
            color = 16777215,
            name = "Common"
        },
        [2] = {
            color = 2031360,
            name = "Uncommon"
        },
        [3] = {
            color = 28893,
            name = "Rare"
        },
        [4] = {
            color = 10696174,
            name = "Epic"
        },
        [5] = {
            color = 16744448,
            name = "Legendary"
        },
        [6] = {
            color = 15125632,
            name = "Artifact"
        },
        [7] = {
            color = 52479,
            name = "Heirloom"
        }
    }
}
local gender

local function GetPlayerIcon(player)
    local race = string.gsub(player:GetRaceAsString(), " ", ""):lower()
    if player:GetGender() == 1 then
        gender = "female"
    else
        gender = "male"
    end
    return auctionConfig.itemIconDB .. 'race_' .. race .. '_' .. gender .. '.jpg'
end

local function EscapeQuotes(text)
    text = string.gsub(input, '"', '\\"')
    text = string.gsub(input, "'", "\\'")
    return text
end

local function ConvertCopperToGoldSilverCopper(copper)
    local gold = math.floor(copper / 10000)
    local remaining = copper % 10000
    local silver = math.floor(remaining / 100)
    local remainingCopper = remaining % 100
    local combinedString = ""
    if gold > 0 then
        combinedString = combinedString .. tostring(gold) .. auctionConfig.goldEmojiID
    end
    if silver > 0 then
        combinedString = combinedString .. tostring(silver) .. auctionConfig.silverEmojiID
    end
    if remainingCopper > 0 then
        combinedString = combinedString .. tostring(remainingCopper) .. auctionConfig.copperEmojiID
    end
    return combinedString
end

local function ConvertSecondsToReadableTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    return hours, minutes
end

local function OnAuctionAdd(event, auctionId, owner, item, expireTime, buyout, startBid, currentBid, bidderGUIDLow)

    bodyStart = string.format(
        '{"content": null, "type": "rich", "embeds": [{"title": "%s", "description": "Item Level: %s", "url": "%s", "color": %d, "fields": [',
        item:GetName(), ' ' .. item:GetItemLevel(), auctionConfig.itemLinkDB .. 'item=' .. tostring(item:GetEntry()),
        auctionConfig.itemQuality[item:GetQuality()].color)

    fields = ""

    -- TODO: Depending on item type, build tooltip fields

    local listing = "Bid: " .. ConvertCopperToGoldSilverCopper(startBid)
    if buyout > 0 then
        listing = listing .. "\\nBuyout: " .. ConvertCopperToGoldSilverCopper(buyout)
    end

    fields = fields .. string.format('{"name": "Selling %d for","value": "%s"}', item:GetCount(), listing)

    bodyEnd = string.format(
        '],"author": {"name": "%s listed", "icon_url": "%s"}, "footer": {"text": "Listed until"}, "timestamp": "%s", "thumbnail": {"url":"https://sinmeowgra.com/api/ah-lua.php?itemid=%i"}}], "username": "Auction House", "attachments": []}',
        owner:GetName(), GetPlayerIcon(owner), os.date("!%Y-%m-%dT%X.000Z", expireTime), item:GetEntry())

    message = bodyStart .. fields .. bodyEnd

    -- Send the message to Discord
    print(message)
    HttpRequest("POST", auctionConfig.auctionWebhookURL, message, "application/json", function(status, body, headers)
        if status ~= 200 then
            print("DiscordNotifier[Lua] Error when sending webhook to discord. Response body is: " .. body)
        end
    end)
end

-- Register the event handler for AUCTION_EVENT_ON_ADD
RegisterServerEvent(26, OnAuctionAdd)
