extends "res://scripts/State Machine/state_machine.gd"


signal move_state_changed(move_state)
signal move_state_stack_changed(state_stack)
signal initialized_values_dic_set(init_values_dic)


var initialized_values = {
	"active_tweens": [],
	
	#Entered Areas Storage
	"areas_entered": [],
	
	#Physics
	"direction": Vector3(),
	"velocity": Vector3(),
	"velocity_gravity": Vector3(),
	"speed": 0.0,
	"landing_speed": 0.0,
	
	#Measurments
	"velocity_3d": 0.0,
	"velocity_horizontal": 0.0,
	"acceleration_3d": 0.0,
	"acceleration_horizontal": 0.0,
	
	#Ledge/Wall Variables
	"ledge_height": 0.0,
	"ledge_grab_transform": Transform(),
	"wall_normal": Vector3(),
	
	#Look Variables
	"view_mode": "third_person",
	"facing_direction": Vector3(),
	"camera_direction": Vector3(),
	"targetting": false,
	"focus_object": null,
	"centered": false,
	"centering_time_left": 0,
	
	#Player Flags
	"is_moving": false,
	"is_falling": false,
	"in_water": false,
	"can_void": true,
	
	#Swim Variables
	"surface_height": 0.0,
	"surfaced_height": 0.0,
	
	#Action State
	"state_action": null,
	
	#Input Variables
	"strafe_locked": false,
	"rotate_to_focus": false,
	"left_joystick_axis": Vector2(),
	"right_joystick_axis": Vector2(),
}


func _ready():
	states_map = {
	"walk": $Walk,
	"jump": $Jump,
	"fall": $Fall,
	"ledge_hang": $Ledge_Hang,
	"ledge_climb": $Ledge_Climb,
	"swim": $Swim,
	"dive": $Dive,
	"death": $Death,
	"void": $Void
}
	#Send out dictionary of initialized values to all states at start
	emit_signal("initialized_values_dic_set", initialized_values)
	
	emit_signal("move_state_changed", states_stack[0].name)
	emit_signal("move_state_stack_changed", states_stack)


func _change_state(state_name): #state_machine.gd does the generalized work
	if not _active:
		return
	
	##State variable initialization (all states are initialized)
	if !(state_name in ["previous"]):
		#Set initialized values in old state for transfer
		current_state.set_initialized_values(current_state.initialized_values)
		#Transfer initialized values to new state
		states_map[state_name].initialize(current_state.initialized_values) #initialize velocity for certain states out of walk state
	
	##Special new state handling
	if state_name in ["walk"] and current_state in [$Ledge_Climb]:
		states_stack.pop_front()
	if state_name in ["fall"] and current_state in [$Jump, $Fall, $Ledge_Hang, $Ledge_Climb, $Swim]:
		states_stack.pop_front()
	if state_name in ["swim"] and current_state in [$Jump, $Fall]:
		states_stack.pop_front()
	if state_name in ["void"] and current_state in [$Jump, $Fall, $Swim]:
		states_stack.pop_front()
		
	##Stack states that stack
	if state_name in ["fall", "jump", "swim", "dive"]: #code for push automaton; "pushes" state_name onto top of state stack
		states_stack.push_front(states_map[state_name])
		
	##Previous State initialization
	if state_name in ["previous"]:
		#Set initialized values in old state for transfer
		current_state.set_initialized_values(current_state.initialized_values)
		#Transfer initialized values to new state
		states_stack[1].initialize(current_state.initialized_values) #pass current state velocity to previous state if switching to previous state
	
	##State Change
	._change_state(state_name)
	
	#Send out dictionary of initialized values for states that don't initialize
	emit_signal("initialized_values_dic_set", initialized_values)
	
	emit_signal("move_state_changed", states_stack[0].name)
	emit_signal("move_state_stack_changed", states_stack)


func _input(_event): #only for handling input that can interrupt other states i.e. something that interrupts jumping
	return


func _on_State_Machine_Action_action_state_changed(action_state):
	initialized_values["state_action"] = action_state

