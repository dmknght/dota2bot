local X = {}
local bot = GetBot()

local J = require( GetScriptDirectory()..'/FunLib/jmz_func' )
local Minion = dofile( GetScriptDirectory()..'/FunLib/aba_minion' )
local sTalentList = J.Skill.GetTalentList( bot )
local sAbilityList = J.Skill.GetAbilityList( bot )
local sOutfitType = J.Item.GetOutfitType( bot )

local tTalentTreeList = {
						['t25'] = {10, 0},
						['t20'] = {0, 10},
						['t15'] = {10, 0},
						['t10'] = {10, 0},
}

local tAllAbilityBuildList = {
						{2,3,2,1,2,6,2,1,1,1,6,3,3,3,6},--pos4,5
}

local nAbilityBuildList = J.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = J.Skill.GetTalentBuild( tTalentTreeList )

local tOutFitList = {}

tOutFitList['outfit_carry'] = tOutFitList['outfit_carry']

tOutFitList['outfit_mid'] = tOutFitList['outfit_carry']

tOutFitList['outfit_tank'] = tOutFitList['outfit_carry']

tOutFitList['outfit_priest'] = {
    "item_tango",
    "item_tango",
    "item_enchanted_mango",
    "item_enchanted_mango",
    "item_double_branches",
    "item_faerie_fire",
    "item_blood_grenade",

    "item_tranquil_boots",
    "item_magic_wand",
    "item_solar_crest",--
    "item_holy_locket",--
    "item_ultimate_scepter",
    "item_force_staff",--
    "item_boots_of_bearing",--
    "item_lotus_orb",--
    "item_wind_waker",--
    "item_aghanims_shard",
    "item_ultimate_scepter_2",
    "item_moon_shard"
}

tOutFitList['outfit_mage'] = {
    "item_tango",
    "item_tango",
    "item_enchanted_mango",
    "item_enchanted_mango",
    "item_double_branches",
    "item_faerie_fire",
    "item_blood_grenade",

    "item_arcane_boots",
    "item_magic_wand",
    "item_solar_crest",--
    "item_holy_locket",--
    "item_ultimate_scepter",
    "item_force_staff",--
    "item_guardian_greaves",--
    "item_lotus_orb",--
    "item_wind_waker",--
    "item_aghanims_shard",
    "item_ultimate_scepter_2",
    "item_moon_shard"
}


X['sBuyList'] = tOutFitList[sOutfitType]

Pos4SellList = {
	"item_magic_wand",
}

Pos5SellList = {
	"item_magic_wand",
}

X['sSellList'] = {}

if sOutfitType == "outfit_priest"
then
    X['sSellList'] = Pos4SellList
elseif sOutfitType == "outfit_mage"
then
    X['sSellList'] = Pos5SellList
end

if J.Role.IsPvNMode() or J.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_antimage' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = J.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = J.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink( hMinionUnit )
	if Minion.IsValidUnit( hMinionUnit )
	then
		if hMinionUnit:IsIllusion()
		then
			Minion.IllusionThink( hMinionUnit )
		end
	end
end

local MistCoil          = bot:GetAbilityByName( 'abaddon_death_coil' )
local AphoticShield     = bot:GetAbilityByName( 'abaddon_aphotic_shield' )
-- local CurseOfAvernus    = bot:GetAbilityByName( 'abaddon_frostmourne' )
-- local BorrowedTimelocal = bot:GetAbilityByName( 'abaddon_borrowed_time' )

local MistCoilDesire, MistCoilTarget
local AphoticShieldDesire, AphoticShieldTarget

function X.SkillsComplement()
	if J.CanNotUseAbility(bot)
    or bot:IsInvisible()
    then
        return
    end

    AphoticShieldDesire, AphoticShieldTarget = X.ConsiderAphoticShield()
    if AphoticShieldDesire > 0
    then
        bot:Action_UseAbilityOnEntity(AphoticShield, AphoticShieldTarget)
        return
    end

    MistCoilDesire, MistCoilTarget = X.ConsiderMistCoil()
    if MistCoilDesire > 0
    then
        bot:Action_UseAbilityOnEntity(MistCoil, MistCoilTarget)
        return
    end
end

function X.ConsiderMistCoil()
    if not MistCoil:IsFullyCastable()
    then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local nCastRange = MistCoil:GetCastRange()
	local nDamage = MistCoil:GetSpecialValueInt('target_damage')
	local nSelfDamage = MistCoil:GetSpecialValueInt('self_damage')
    local nDamageType = DAMAGE_TYPE_MAGICAL
    local botTarget = J.GetProperTarget(bot)

    if J.HasAghanimsShard(bot)
    then
        nDamage = bot:GetAttackDamage()
        nDamageType = DAMAGE_TYPE_PURE
    end

    local nEnemyHeroes = bot:GetNearbyHeroes(nCastRange, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if  J.IsValidHero(enemyHero)
        and J.CanCastOnMagicImmune(enemyHero)
        and J.CanKillTarget(enemyHero, nDamage, nDamageType)
        and not J.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            return BOT_ACTION_DESIRE_HIGH, enemyHero
        end
    end

    local nAllyHeroes = bot:GetNearbyHeroes(nCastRange, false, BOT_MODE_NONE)
	for _, allyHero in pairs(nAllyHeroes)
	do
        if  J.IsValidHero(allyHero)
        and not allyHero:IsInvulnerable()
        and not allyHero:IsIllusion()
        and (allyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
            or allyHero:HasModifier('modifier_enigma_black_hole_pull'))
        then
            return BOT_ACTION_DESIRE_HIGH, allyHero
        end

		if  J.IsValidHero(allyHero)
		and J.IsInRange(bot, allyHero, nCastRange)
		and not allyHero:HasModifier('modifier_legion_commander_press_the_attack')
		and not allyHero:IsMagicImmune()
		and not allyHero:IsInvulnerable()
        and not allyHero:IsIllusion()
		and allyHero:CanBeSeen()
		then
			if  J.IsRetreating(allyHero)
            and J.GetHP(allyHero) < 0.6
			then
				return BOT_ACTION_DESIRE_HIGH, allyHero
			end

			if J.IsGoingOnSomeone(allyHero)
			then
                local allyTarget = allyHero:GetAttackTarget()

				if  J.IsValidHero(allyTarget)
				and allyHero:IsFacingLocation(allyTarget:GetLocation(), 30)
				and J.IsInRange(allyHero, allyTarget, 300)
                and J.GetHP(allyHero) < 0.8
                and J.GetHP(bot) > 0.2
				then
					return BOT_ACTION_DESIRE_HIGH, allyHero
				end
			end
		end
	end

    if  J.IsRetreating(bot)
    and J.IsInRange(bot, botTarget, nCastRange)
	then
        local nInRangeAlly = bot:GetNearbyHeroes(nCastRange + 200, false, BOT_MODE_NONE)
        local nInRangeEnemy = bot:GetNearbyHeroes(nCastRange, true, BOT_MODE_NONE)

        if  nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        and ((#nInRangeAlly == 0 and #nInRangeEnemy >= 1)
            or (#nInRangeAlly >= 1
                and J.GetHP(bot) < 0.25
                and bot:WasRecentlyDamagedByAnyHero(1)
                and not bot:HasModifier('modifier_abaddon_borrowed_time')))
        and J.IsValidHero(nInRangeEnemy[1])
        and not J.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not J.IsDisabled(J.IsValidHero(nInRangeEnemy[1]))
        then
            return BOT_ACTION_DESIRE_HIGH, bot
        end
	end

	return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderAphoticShield()
    if not AphoticShield:IsFullyCastable()
    then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local nCastRange  = AphoticShield:GetCastRange()
    local botTarget = J.GetProperTarget(bot)

    local nAllyHeroes = bot:GetNearbyHeroes(nCastRange, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
	do
        if  J.IsValidHero(allyHero)
        and not allyHero:IsInvulnerable()
        and not allyHero:IsIllusion()
        and (allyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
            or allyHero:HasModifier('modifier_enigma_black_hole_pull'))
        then
            return BOT_ACTION_DESIRE_HIGH, allyHero
        end

        if  J.IsValidHero(allyHero)
        and J.IsDisabled(allyHero)
        and not allyHero:IsMagicImmune()
		and not allyHero:IsInvulnerable()
        and not allyHero:IsIllusion()
        then
            return BOT_ACTION_DESIRE_HIGH, allyHero
        end

		if  J.IsValidHero(allyHero)
        and not allyHero:HasModifier('modifier_abaddon_aphotic_shield')
        and not allyHero:HasModifier('modifier_item_solar_crest_armor_addition')
		and not allyHero:IsMagicImmune()
		and not allyHero:IsInvulnerable()
        and not allyHero:IsIllusion()
		and allyHero:CanBeSeen()
        and J.IsNotSelf(bot, allyHero)
		then
            local nInRangeEnemy = bot:GetNearbyHeroes(nCastRange + 200, true, BOT_MODE_NONE)

            if  J.IsRetreating(allyHero)
            and nInRangeEnemy ~= nil
            and ((#nInRangeEnemy > #nAllyHeroes)
                or (J.GetHP(allyHero) < 0.65 and allyHero:WasRecentlyDamagedByAnyHero(1.5)))
            and J.IsValidHero(nInRangeEnemy[1])
            and not J.IsSuspiciousIllusion(nInRangeEnemy[1])
            and not J.IsDisabled(nInRangeEnemy[1])
			then
				return BOT_ACTION_DESIRE_HIGH, allyHero
			end

			if J.IsGoingOnSomeone(allyHero)
			then
				local allyTarget = allyHero:GetAttackTarget()

				if  J.IsValidHero(allyTarget)
				and J.IsInRange(allyHero, allyTarget, allyHero:GetAttackRange())
                and not J.IsSuspiciousIllusion(allyTarget)
                and not allyTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
                and not allyTarget:HasModifier('modifier_enigma_black_hole_pull')
                and nInRangeEnemy ~= nil
                and #nAllyHeroes >= #nInRangeEnemy
				then
					return BOT_ACTION_DESIRE_HIGH, allyHero
				end
			end
		end
	end

	if J.IsGoingOnSomeone(bot)
    then
		local nInRangeAlly = bot:GetNearbyHeroes(nCastRange + 150, false, BOT_MODE_NONE)
        local nInRangeEnemy = bot:GetNearbyHeroes(nCastRange, true, BOT_MODE_NONE)

		if  J.IsValidTarget(botTarget)
        and J.IsInRange(bot, botTarget, nCastRange)
        and not J.IsSuspiciousIllusion(botTarget)
        and not J.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
        and nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        and #nInRangeAlly >= #nInRangeEnemy
        then
			if  J.IsValidHero(nInRangeAlly[1])
            and J.IsInRange(bot, nInRangeAlly[1], nCastRange)
            and J.IsCore(nInRangeAlly[1])
            and not nInRangeAlly[1]:HasModifier('modifier_abaddon_aphotic_shield')
            and not nInRangeAlly[1]:IsMagicImmune()
            and not nInRangeAlly[1]:IsInvulnerable()
            and not nInRangeAlly[1]:IsIllusion()
            then
                return BOT_ACTION_DESIRE_HIGH, nInRangeAlly[1]
            end

            if  not bot:HasModifier('modifier_abaddon_aphotic_shield')
            and not bot:HasModifier("modifier_abaddon_borrowed_time")
            then
                return BOT_ACTION_DESIRE_MODERATE, bot
            end
	    end

        if  nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        and #nInRangeAlly == 0 and #nInRangeEnemy >= 1
        and J.IsValidHero(nInRangeEnemy[1])
        and J.IsInRange(bot, nInRangeEnemy[1], nCastRange)
        and not J.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not J.IsDisabled(nInRangeEnemy[1])
        and not bot:HasModifier('modifier_abaddon_aphotic_shield')
        and not bot:HasModifier("modifier_abaddon_borrowed_time")
        then
            return BOT_ACTION_DESIRE_MODERATE, bot
        end
    end

    if  J.IsRetreating(bot)
    and not bot:HasModifier('modifier_abaddon_aphotic_shield')
    and not bot:HasModifier("modifier_abaddon_borrowed_time")
	then
        local nInRangeAlly = bot:GetNearbyHeroes(nCastRange + 200, false, BOT_MODE_NONE)
        local nInRangeEnemy = bot:GetNearbyHeroes(nCastRange, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy
        and ((#nInRangeEnemy > #nInRangeAlly)
            or J.GetHP(bot) < 0.55 and bot:WasRecentlyDamagedByAnyHero(2))
        and J.IsValidHero(nInRangeEnemy[1])
        and J.IsInRange(bot, nInRangeEnemy[1], nCastRange - 75)
        and not J.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not J.IsDisabled(nInRangeEnemy[1])
        then
            return BOT_ACTION_DESIRE_MODERATE, bot
        end
	end

	return BOT_ACTION_DESIRE_NONE, nil
end

return X