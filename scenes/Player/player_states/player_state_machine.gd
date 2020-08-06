extends "res://scripts/State Machine/state_machine.gd"


signal state_changed(current_state)
signal state_stack_changed(state_stack)
signal initialized_values_dic_set(init_values_dic)

var initialized_values = {
	"velocity": Vector3(),
	"focus_target_pos": null,
	"cast_jump": false,
	"is_walking": false,
	"is_falling": false,
	"centered": false,
	"centering_time_left": 0,
	"left_joystick_axis": Vector2(),
	"right_joystick_axis": Vector2(),
}

func _ready():
	states_map = {
	"idle": $Idle,
	"walk": $Walk,
	"fall": $Fall,
	"jump": $Jump,
	"ground_cast": $Ground_Cast,
	"air_cast": $Air_Cast,
	"death": $Death,
	"void": $Void
}
	#Send out dictionary of initialized values to all states at start
	emit_signal("initialized_values_dic_set", initialized_values)
	
	emit_signal("state_changed", states_stack[0].get_name())
	emit_signal("state_stack_changed", states_stack)


func _change_state(state_name): #state_machine.gd does the generalized work
	if not _active:
		return
	##States that stack
	if state_name in ["fall", "jump", "ground_cast", "air_cast"]: #code for push automaton; "pushes" state_name onto top of state stack
		states_stack.push_front(states_map[state_name])
	##New State initialization (excludes idle for some reason)
	if state_name in ["idle", "walk", "fall", "jump", "ground_cast", "air_cast", "void"]:
		#Set initialized values in old state for transfer
		current_state.set_initialized_values(current_state.initialized_values)
		#Transfer initialized values to new state
		states_map[state_name].initialize(current_state.initialized_values) #initialize velocity for certain states out of walk state
	##Jumping/Falling during Ground Cast
	if state_name in ["jump", "fall"] and current_state in [$Ground_Cast]:
		states_stack.pop_front()
	##Going from Air Cast to Ground Cast
	if state_name in ["ground_cast"] and current_state in [$Air_Cast]:
		states_stack.pop_front()
		states_stack.pop_front()
		states_stack.pop_front()
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
	
	emit_signal("state_changed", states_stack[0].get_name())
	emit_signal("state_stack_changed", states_stack)


func _input(event): #only for handling input that can interrupt other states i.e. something that interrupts jumping
	return


