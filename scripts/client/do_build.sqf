build_confirmed = 0;
_maxdist = 125;
_truepos = [];

if (isNil "manned") then { manned = false };
if (isNil "gridmode" ) then { gridmode = 0 };
if (isNil "repeatbuild" ) then { repeatbuild = false };
if (isNil "build_rotation" ) then { build_rotation = 0 };

waitUntil { !isNil "dobuild" };

while { true } do {
	waitUntil { dobuild != 0 };
	build_confirmed = 1;
	build_invalid = 0;
	_classname = "";
	if ( buildtype == 99 ) then {
		removefobboxes = true;
		_classname = FOB_typename;
	} else {
		_classname = (((build_lists select buildtype) select buildindex) select 0);
		_built_object_remote = [buildtype,buildindex,player];
		[ [_built_object_remote] , "build_remote_call" ] call BIS_fnc_MP;
	};

	if(buildtype == 1) then {
		_pos = [(getpos player select 0) + 1,(getpos player select 1) + 1, 0];
		_grp = group player;
		if ( manned ) then {
			_grp = createGroup WEST;
		};
		_classname createUnit [_pos, _grp,"this addMPEventHandler [""MPKilled"", {_this spawn kill_manager}]", 0.5, "private"];
		build_confirmed = 0;
	} else {
		if ( buildtype == 8 ) then {
			_pos = [(getpos player select 0) + 1,(getpos player select 1) + 1, 0];
			_grp = createGroup WEST;
			_grp setGroupId [format ["%1 %2",squads_names select buildindex, groupId _grp]];
			_idx = 0;
			{ 
				_unitrank = "private";
				if(_idx == 0) then { _unitrank = "sergeant"; };
				if(_idx == 1) then { _unitrank = "corporal"; };
				_x createUnit [_pos, _grp,"this addMPEventHandler [""MPKilled"", {_this spawn kill_manager}]", 0.5, _unitrank]; 
				_idx = _idx + 1;
			
			} foreach _classname;
			build_confirmed = 0;
		} else {
			_posfob = getpos player;
			if (buildtype != 99) then {
				_posfob = call F_getNearestFob;
			};

			_idactcancel = -1;
			_idactsnap = -1;
			_idactplacebis = -1;
			if (buildtype == 6 ) then {
				_idactcancel = player addAction ["<t color='#B0FF00'>" + localize "STR_CANCEL" + "</t> <img size='2' image='res\ui_cancel.paa'/>","scripts\client\build_cancel.sqf","",-725,false,true,"","build_confirmed == 1"];
				_idactplacebis = player addAction ["<t color='#B0FF00'>" + localize "STR_PLACEMENT_BIS" + "</t> <img size='2' image='res\ui_confirm.paa'/>","scripts\client\build_place_bis.sqf","",-785,false,false,"","build_invalid == 0 && build_confirmed == 1"];
			};
			if (buildtype == 6 || buildtype == 99) then {
				_idactsnap = player addAction ["<t color='#B0FF00'>" + localize "STR_GRID" + "</t>","scripts\client\do_grid.sqf","",-735,false,false,"","build_confirmed == 1"];
			};
			_idactrotate = player addAction ["<t color='#B0FF00'>" + localize "STR_ROTATION" + "</t> <img size='2' image='res\ui_rotation.paa'/>","scripts\client\build_rotate.sqf","",-750,false,false,"","build_confirmed == 1"];
			_idactplace = player addAction ["<t color='#B0FF00'>" + localize "STR_PLACEMENT" + "</t> <img size='2' image='res\ui_confirm.paa'/>","scripts\client\build_place.sqf","",-775,false,true,"","build_invalid == 0 && build_confirmed == 1"];
			
			_ghost_spot = (getmarkerpos "ghost_spot") findEmptyPosition [0,100];

			_vehicle = _classname createVehicleLocal _ghost_spot;
			_vehicle allowdamage false;
			_vehicle setVehicleLock "LOCKED";
			_vehicle enableSimulationGlobal false;
			
			_dist = 0.6 * (sizeOf _classname);
			if (_dist < 2.5) then { _dist = 2.5 };
			_dist = _dist + 1.5;

			for [{_i=0}, {_i<5}, {_i=_i+1}] do {
				_vehicle setObjectTextureGlobal [_i, '#(rgb,8,8,3)color(0,1,0,0.8)'];
			};
			
			while { build_confirmed == 1 && alive player } do {
				_truedir = 90 - (getdir player);
				_truepos = [((getpos player) select 0) + (_dist * (cos _truedir)), ((getpos player) select 1) + (_dist * (sin _truedir)),0];
				_actualdir = ((getdir player) + build_rotation);
				if ( _classname == "Land_Cargo_Patrol_V1_F" || _classname == "Land_PortableLight_single_F" ) then { _actualdir = _actualdir + 180 };
				if ( _classname == FOB_typename ) then { _actualdir = _actualdir + 270 };
				
				while { _actualdir > 360 } do { _actualdir = _actualdir - 360 };
				while { _actualdir < 0 } do { _actualdir = _actualdir + 360 };
				if ( ((buildtype == 6) || (buildtype == 99)) && ((gridmode % 2) == 1) ) then {
					if ( _actualdir >= 22.5 && _actualdir <= 67.5 ) then { _actualdir = 45 };
					if ( _actualdir >= 67.5 && _actualdir <= 112.5 ) then { _actualdir = 90 };
					if ( _actualdir >= 112.5 && _actualdir <= 157.5 ) then { _actualdir = 135 };
					if ( _actualdir >= 157.5 && _actualdir <= 202.5 ) then { _actualdir = 180 };
					if ( _actualdir >= 202.5 && _actualdir <= 247.5 ) then { _actualdir = 225 };
					if ( _actualdir >= 247.5 && _actualdir <= 292.5 ) then { _actualdir = 270 };
					if ( _actualdir >= 292.5 && _actualdir <= 337.5 ) then { _actualdir = 315 };
					if ( _actualdir <= 22.5 || _actualdir >= 337.5 ) then { _actualdir = 0 };
				};
				
				_vehicle setdir _actualdir;
				
				_near_objects = (_truepos nearobjects ["AllVehicles", _dist]) ;
				_near_objects = _near_objects + (_truepos nearobjects [FOB_box_typename, _dist]);
				_near_objects = _near_objects + (_truepos nearobjects [Arsenal_typename, _dist]);
				
				_near_objects_25 = (_truepos nearobjects ["AllVehicles", 25]) ;
				_near_objects_25 = _near_objects_25 + (_truepos nearobjects [FOB_box_typename, 25]);
				_near_objects_25 = _near_objects_25 + (_truepos nearobjects [Arsenal_typename, 25]);
				
				if(	buildtype != 6 ) then {
					_near_objects = _near_objects + (_truepos nearobjects ["Static", _dist]);
					_near_objects_25 = _near_objects_25 + (_truepos nearobjects ["Static", 25]);
				};
				
				_remove_objects = (_truepos nearobjects ["Animal", 25]) + (_truepos nearobjects ["land_runway_edgelight", 25]) + (_truepos nearobjects ["land_runway_edgelight_blue_f", 25]) + (_truepos nearobjects ["Land_HelipadSquare_F", 25]) +  [player, _vehicle];
				
				_near_objects = _near_objects - _remove_objects;
				_near_objects_25 = _near_objects_25 - _remove_objects;
				
				if ( count _near_objects == 0 ) then {
					{
						_dist22 = 0.55 * (sizeOf (typeof _x));
						if (_truepos distance _x < _dist22) then {
							_near_objects = _near_objects + [_x];
						};
					} foreach _near_objects_25;
				};
				
				if (count _near_objects == 0 && ((_truepos distance _posfob) < _maxdist) && (!surfaceIsWater _truepos) && (!surfaceIsWater getpos player)) then {

					if ( ((buildtype == 6) || (buildtype == 99)) && ((gridmode % 2) == 1) ) then {
						_vehicle setpos [round (_truepos select 0),round (_truepos select 1), _truepos select 2];
					} else {
						_vehicle setpos _truepos;
					};
					if ( buildtype == 6 || buildtype == 99 ) then {
						_vehicle setVectorUp [0,0,1];
					} else {
						_vehicle setVectorUp surfaceNormal position _vehicle;
					};
					if(build_invalid == 1) then {
						hint localize "STR_PLACEMENT_POSSIBLE";
					};
					build_invalid = 0;
				} else {
					_vehicle setpos _ghost_spot;
					build_invalid = 1;
					if(count _near_objects > 0) then {
						hint format [localize "STR_PLACEMENT_IMPOSSIBLE",count _near_objects, round _dist];
					};
					if((surfaceIsWater _truepos) || (surfaceIsWater getpos player)) then {
						hint localize "STR_BUILD_ERROR_WATER";
					};
					if((_truepos distance _posfob) > _maxdist) then {
						hint format [localize "STR_BUILD_ERROR_DISTANCE",_maxdist];
					};
				};
				sleep 0.05;
			};
			
			if ( !alive player || build_confirmed == 3 ) then {
				deleteVehicle _vehicle;
			};

			if ( build_confirmed == 2 ) then {
				_vehpos = getpos _vehicle;
				_vehdir = getdir _vehicle;
				deleteVehicle _vehicle;
				sleep 0.1;
				_vehicle = _classname createVehicle _truepos;
				_vehicle allowDamage false;
				_vehicle setdir _vehdir;
				_vehicle setpos _truepos;
				if ( buildtype == 6 || buildtype == 99 ) then {
					_vehicle setVectorUp [0,0,1];
				} else {
					_vehicle setVectorUp surfaceNormal position _vehicle;
				};
				clearWeaponCargoGlobal _vehicle;
				clearMagazineCargoGlobal _vehicle;
				clearItemCargoGlobal _vehicle;
				clearBackpackCargoGlobal _vehicle;
				if ( (_classname in uavs) || manned ) then {
					createVehicleCrew _vehicle;
				};
				sleep 0.3;
				_vehicle allowDamage true;
				_vehicle setDamage 0;
				if(buildtype != 6) then {
					_vehicle addMPEventHandler ["MPKilled", {_this spawn kill_manager}];
					{ _x addMPEventHandler ["MPKilled", {_this spawn kill_manager}]; } foreach (crew _vehicle);
				
				};
			};
			
			if ( _idactcancel != -1 ) then {
				player removeAction _idactcancel;
			};
			if ( _idactsnap != -1 ) then {
				player removeAction _idactsnap;
			};
			if ( _idactplacebis != -1 ) then {
				player removeAction _idactplacebis;
			};
			player removeAction _idactrotate;
			player removeAction _idactplace;
			
			if(buildtype == 99) then {
				_new_fob = getpos player;
				[ [_new_fob] , "build_fob_remote_call" ] call BIS_fnc_MP;
				buildtype = 1;
			};
			
			build_confirmed = 0;
		};
	};
	
	if ( repeatbuild ) then {
		dobuild = 1;
		repeatbuild = false;
	} else {
		dobuild = 0;
	};
	manned = false;
};