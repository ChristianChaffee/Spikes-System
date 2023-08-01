main() {}

#include <a_samp>
#include <streamer>

//===================================================================
#define MAX_SERVER_SPIKES 	50
#define SPIKE_DESTROY_TIME 	180

static vehicleSpikesCount [MAX_VEHICLES] = { 5, ... };
static totalSpikes;


enum spike_info_enum
{
	sObjectID,
	sTime,
	sArea,
}
static spikesInfoEmpty [spike_info_enum] = {
	INVALID_OBJECT_ID, 0, -1
};
static spikesInfo [MAX_SERVER_SPIKES][spike_info_enum];

//===================================================================

public OnGameModeInit()
{
	SetTimer("spikesTimerFunction", 1000, true);
	return 1;
}

public OnGameModeExit()
{
	DestroySpike();
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	if(IsAPoliceCar(vehicleid) && vehicleSpikesCount [vehicleid] < 5)
		vehicleSpikesCount [vehicleid] = 5;
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(newkeys == KEY_SUBMISSION
		&& GetPlayerState(playerid) == PLAYER_STATE_DRIVER
		&& IsAPoliceCar(GetPlayerVehicleID(playerid))
		&& totalSpikes < MAX_SERVER_SPIKES
		&& vehicleSpikesCount [GetPlayerVehicleID(playerid)] > 0)
	{
		new Float:Pos[4];
		GetCoordBootVehicle(GetPlayerVehicleID(playerid),
			Pos[0], Pos[1], Pos[2]);
		GetVehicleZAngle(GetPlayerVehicleID(playerid), Pos[3]);
		CreateSpike(Pos[0], Pos[1], Pos[2], Pos[3]);

		vehicleSpikesCount [GetPlayerVehicleID(playerid)]--;
		totalSpikes++;
	}
	return 1;
}

public OnPlayerEnterDynamicArea(playerid, areaid)
{
	if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER && !IsAPoliceCar(GetPlayerVehicleID(playerid)))
	{
		for(new i; i < MAX_SERVER_SPIKES; i++)
		{
			if(areaid == spikesInfo [i][sArea])
			{
				new panels, doors, lights, tires;
	            GetVehicleDamageStatus(GetPlayerVehicleID(playerid), panels, doors, lights, tires);
	            UpdateVehicleDamageStatus(GetPlayerVehicleID(playerid), panels, doors, lights, 15);
	            break;
			}
		}
	}
}

//===================================================================

static IsAPoliceCar(vehicleid)
{
	switch(GetVehicleModel(vehicleid))
	{
		case 596..599: return true;
	}
	return false;
}

static GetCoordBootVehicle(vehicleid, &Float:x, &Float:y, &Float:z)
{
    new Float:angle, Float:distance;
    GetVehicleModelInfo(GetVehicleModel(vehicleid), 1, x, distance, z);
    distance = distance/2 + 0.1;
    GetVehiclePos(vehicleid, x, y, z);
    GetVehicleZAngle(vehicleid, angle);
    x += (distance * floatsin(-angle+180, degrees));
    y += (distance * floatcos(-angle+180, degrees));
    return true;
}
//===================================================================
static CreateSpike(Float:x, Float:y, Float:z, Float:angle)
{
	if(totalSpikes >= MAX_SERVER_SPIKES)
		return false;

	new spikeid;
	for(new i; i < MAX_SERVER_SPIKES; i++)
	{
		if(spikesInfo [i][sObjectID] == INVALID_OBJECT_ID)
		{
			spikeid = i;
			break;
		}
	}

	spikesInfo [spikeid][sTime] = SPIKE_DESTROY_TIME;
	spikesInfo [spikeid][sObjectID] = CreateDynamicObject(2892, x, y, z - 0.5, 0.0, 0.0, angle + 90.0, 0, 0);
	spikesInfo [spikeid][sArea] = CreateDynamicSphere(x, y, z, 4.2, 0, 0);
	return true;
}

static DestroySpike(spikeid = -1)
{
	if(spikeid == -1)
	{
		for(new i; i < MAX_SERVER_SPIKES; i++)
		{
			if(spikesInfo [i][sObjectID] != INVALID_OBJECT_ID)
			{
				DestroyDynamicObject(spikesInfo [i][sObjectID]);
				DestroyDynamicArea(spikesInfo [i][sArea]);
			}

			spikesInfo [i] = spikesInfoEmpty;
		}

		totalSpikes = 0;
		return true;
	}
	else if(spikeid >= 0 && spikeid < MAX_SERVER_SPIKES-1)
	{
		if(spikesInfo [spikeid][sObjectID] != INVALID_OBJECT_ID)
		{
			DestroyDynamicObject(spikesInfo [spikeid][sObjectID]);
			DestroyDynamicArea(spikesInfo [spikeid][sArea]);
		}

		spikesInfo [spikeid] = spikesInfoEmpty;
		totalSpikes--;
		return true;
	}
	else return false;
}

forward spikesTimerFunction();
public spikesTimerFunction()
{
	for(new i; i < MAX_SERVER_SPIKES; i++)
	{
		if(spikesInfo [i][sTime] > 0)
		{
			spikesInfo [i][sTime]--;

			if(spikesInfo [i][sTime] <= 0)
				DestroySpike(i);
		}
	}
}