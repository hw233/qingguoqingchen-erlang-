%%% -------------------------------------------------------------------
%%% 9������ȫ���״ο�Դ����
%%% http://www.9miao.com
%%% -------------------------------------------------------------------
%% Author: Administrator
%% Created: 2013-5-10
%% Description: TODO: Add description to msql_data_delete
-module(msql_data_delete).
-compile(export_all).
-include("config_db_def.hrl").
-define(DB, conn).
%%
%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([]).

%%
%% API Functions
%%



%%
%% Local Functions
%%
delete_data()->
	delete(achieve_proto),
	delete(achieve_fuwen),
	delete(achieve_award),
	delete(achieve),
	delete(activity),
	delete(activity_value_proto),
	delete(activity_value_reward),
	delete(ai_agents),
	delete(achieve_award),
	delete(answer),
	delete(answer_option),
	delete(attr_info),
	delete(auto_name),
	delete(back_echantment_stone),
	delete(battlefield_proto),
	delete(block_training),
	delete(buffers),
	delete(chat_condition),
	delete(chess_spirit_config),
	delete(chess_spirit_rewards),
	delete(chess_spirit_section),
	delete(christmas_activity_reward),
	delete(achieve_award),
	delete(christmas_tree_config),
	delete(classbase),
	delete(congratulations),
	delete(continuous_logging_gift),
	delete(country_proto),
	delete(creature_proto),
	delete(designation_data),
	delete(dragon_fight_db),
	delete(drop_rule),
	delete(enchantments),
	delete(enchantments_lucky),
	delete(enchant_convert),
	delete(enchant_opt),
	delete(enchant_property_opt),
	delete(equipmentset),
	delete(equipment_fenjie),
	delete(equipment_move),
	delete(equipment_sysbrd),
	delete(equipment_upgrade),
	delete(everquests),
	delete(faction_relations),
	delete(festival_control),
	delete(festival_recharge_gift),
	delete(goals),
	delete(guild_authorities),
	delete(guild_auth_groups),
	delete(guild_battle_proto),
	delete(guild_facilities),
	delete(guild_monster_proto),
	delete(guild_setting),
	delete(guild_shop),
	delete(guild_shop_items),
	delete(guild_treasure),
	delete(guild_treasure_items),
	delete(guild_treasure_transport_consume),
	delete(honor_store_items),
	delete(inlay),
	delete(instance_proto),
	delete(item_identify),
	delete(item_template),
	delete(jszd_rank_option),
	delete(levelup_opt),
	delete(level_activity_rewards_db),
	delete(loop_instance),
	delete(loop_instance_proto),
	delete(loop_tower),
	delete(lottery_counts),
	delete(lottery_droplist),
	delete(mainline_defend_config),
	delete(mainline_proto),
	delete(mall_item_info),
	delete(mall_sales_item_info),
	delete(map_info),
	delete(npc_dragon_fight),
	delete(npc_drop),
	delete(npc_exchange_list),
	delete(everquest_list),
	delete(npc_sell_list),
	delete(npc_trans_list),
	delete(quest_npc),
	delete(npc_functions),
	delete(offline_everquests_exp),
	delete(offline_exp),
	delete(open_service_activities),
	delete(open_service_activities_time),
	delete(pet_evolution),
	delete(pet_explore_gain),
	delete(pet_explore_style),
	delete(pet_growth),
	delete(pet_happiness),
	delete(pet_level),
	delete(pet_proto),
	delete(pet_quality),
	delete(pet_quality_up),
	delete(pet_skill_slot),
	delete(pet_slot),
	delete(pet_talent_consume),
	delete(pet_talent_rate),
	delete(pet_wash_attr_point),
	delete(pet_item_mall),
	delete(quests),
	delete(refine_system),
	delete(remove_seal),
	delete(ridepet_synthesis),
	delete(ride_proto_db),
	delete(role_level_bonfire_effect_db),
	delete(role_level_experience),
	delete(role_level_sitdown_effect_db),
	delete(role_level_soulpower),
	delete(role_petnum),
	delete(series_kill),
	delete(skills),
	delete(sock),
	delete(spa_exp),
	delete(spa_option),
	delete(stonemix),
	delete(system_chat),
	delete(tangle_reward_info),
	delete(template_itemproto),
	delete(timelimit_gift),
	delete(transports),
	delete(transport_channel),
	delete(treasure_chest_drop),
	delete(treasure_chest_rate),
	delete(treasure_chest_times),
	delete(treasure_chest_type),
	delete(treasure_spawns),
	delete(treasure_transport),
	delete(treasure_transport_quality_bonus),
	delete(venation_advanced),
	delete(venation_exp_proto),
	delete(venation_item_rate),
	delete(venation_point_proto),
	delete(venation_proto),
	delete(vip_level),
	delete(welfare_activity_data),
	delete(yhzq_battle),
	delete(yhzq_winner_raward),
	delete(creature_spawns),
	delete(template_roleattr),
	delete(template_role_quick_bar),
	delete(template_role_skill),
	delete(template_quest_role),
	delete(instance_quality_proto),
	delete(pet_skill_template),
	delete(pet_skill_proto),
	delete(instance_entrust),
	delete(activity_test01),
	delete(pet_attr_transform),
	delete(pet_up_growth),
	delete(stonemix_rateinfo),
	delete(pet_skill_book_rate),
	delete(pet_skill_book),
	delete(pet_fresh_skill),
	delete(pet_base_attr),
	delete(pet_xisui_rate),
	delete(pet_talent_item),
	delete(pet_talent_proto),
	delete(pet_talent_template),
	delete(pet_advance),
	delete(pet_advance_lucky),
	delete(wing_level),
	delete(wing_phase),
	delete(wing_intensify_up),
	delete(wing_quality),
	delete(wing_skill),
	delete(item_gold_price),
	delete(wing_echant),
	delete(wing_echant_lock),
	delete(charge_package_proto),
	delete(item_can_used).

delete_dyna_data()->
		delete(account),
		delete(achieve_role),
		delete(activity_info_db),
		delete(activity_test01_role),
		delete(answer_roleinfo),
		delete(auto_name_used),
		delete(background_welfare_data),
		delete(black),
		delete(christmas_tree_db),
		delete(consume),
		delete(consume_return_info),
		delete(country_record),
		delete(enchant_extremely_property_opt),
		delete(facebook_bind),
		delete(fatigue),
		delete(festival_control_background),
		delete(festival_recharge_gift_bg),
		delete(friend),
		delete(game_rank_db),
		delete(giftcards),
		delete(global_exp_addition_db),
		delete(global_monster_loot_db),
		delete(gm_blockade),
		delete(gm_notice),
		delete(gm_role_privilege),
		delete(goals_role),
		delete(guild_baseinfo),
		delete(guild_battle_result),
		delete(guild_battle_score),
		delete(guild_events),
		delete(guild_facility_info),
		delete(guild_impeach_info),
		delete(guild_leave_member),
		delete(guild_log),
		delete(guild_member),
		delete(guild_member_shop),
		delete(guild_member_treasure),
		delete(guild_monster),
		delete(guild_right_limit),
		delete(guild_treasure_price),
		delete(guilditems),
		delete(guildpackage_apply),
		delete(idmax),
		delete(invite_friend),
		delete(jszd_role_score_honor),
		delete(jszd_role_score_info),
		delete(loop_instance_record),
		delete(loop_tower_instance),
		delete(mail),
		delete(mall_up_sales_table),
		delete(offline_exp_rolelog),
		delete(open_service_activitied_control),
		delete(open_service_level_rank_db),
		delete(pet_advance_reset_time),
		delete(pet_explore_background),
		delete(pet_explore_info),
		delete(pet_shop_info),
		delete(pets),
		delete(player_option),
		delete(playeritems),
		delete(quest_role),
		delete(recharge1),
		delete(role_activity_value),
		delete(role_buy_log),
		delete(role_buy_mall_item),
		delete(role_chess_spirit_log),
		delete(role_congratu_log),
		delete(role_continuous_logging_info),
		delete(role_designation_info),
		delete(role_favorite_gift_info),
		delete(role_festival_recharge_data),
		delete(role_first_charge_gift),
		delete(role_gold_exchange_info),
		delete(role_instance),
		delete(role_invite_friend_info),
		delete(role_judge_left_num),
		delete(role_judge_num),
		delete(role_levelup_opt_record),
		delete(role_login_bonus),
		delete(role_loop_instance),
		delete(role_loop_tower),
		delete(role_lottery),
		delete(role_mainline),
		delete(role_mall_integral),
		delete(role_quick_bar),
		delete(role_service_activities_db),
		delete(role_skill),
		delete(role_sum_gold),
		delete(role_timelimit_gift),
		delete(role_treasure_transport_db),
		delete(role_venation),
		delete(role_venation_advanced),
		delete(role_welfare_activity_info),
		delete(roleattr),
		delete(signature),
		delete(tangle_battle),
		delete(tangle_battle_kill_info),
		delete(tangle_battle_role_killnum),
		delete(template_playeritems),
		delete(vip_role),
		delete(yhzq_battle_record),
		delete(furnace),
		delete(furnace_add_role_attribute),
		delete(astrology_package),
		delete(astrology_add_role_attribute).
		
delete(TableName)->
	Sql="delete  from "++lists:flatten(io_lib:write(TableName)),
%% 	io:format("~p ~n",[Sql]),
	mysql:fetch(?DB, Sql).