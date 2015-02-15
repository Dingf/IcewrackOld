--[[
    Icewrack Damage Types
    
    PURE:
        *Cannot be resisted, unaffected by damage pierce or damage block (but IS affected by incoming/outgoing damage modifiers)
        *Used by holy/arcane spells (think SWM Arcane Bolt, Chen's Test of Faith, etc.)
        *This is the default damage type if none is specified
        
    PHYSICAL:
        *Armor is treated as physical damage block (not percent resistance)
		*Critical strikes stun the target for up to 5 seconds, based on the percentage of max. HP dealt
        *Critical strikes shatter Frozen and Petrified enemies
        *Used by most autoattacks and some elemental spells (mostly wind/earth)
        
    FIRE:
		*High damage, low variance
        *Critical strikes deal 50% of the original damage dealt as burning damage, which does 1% max. HP per sec. (NYI)
		*Removes Chilled and Frozen and Wet on impact (NYI)
        *Used by fire spells and attacks (duh)
        
    ICE:
        *Critical strikes slow the victim's movement and attack speed by 50% for up to 10 seconds, based on the percentage of max. HP dealt as damage (Chill)
		*Removes Burning on Impact (NYI)
        *Used by ice spells, and overexposure to cold (maybe?)
		*Medium damage, low variance
        
    LIGHTNING:
		*Critical strikes burn mana and stamina equal to 50% of the damage dealt (Shock) (NYI)
        *Should have a high damage range (think D2 lightning spells, i.e. 1-700 damage)
    
    DEATH:
        *Critical strikes deal 25% of the target's current HP as bonus, uncrittable Death damage (Deathblow) (NYI)
        *Used by poison spells (these shouldn't be able to crit), as well as unholy/death-themed spells
]]

IW_DAMAGE_TYPE_PURE = 0
IW_DAMAGE_TYPE_PHYSICAL = 1
IW_DAMAGE_TYPE_FIRE = 2
IW_DAMAGE_TYPE_ICE = 3
IW_DAMAGE_TYPE_LIGHTNING = 4
IW_DAMAGE_TYPE_DEATH = 5