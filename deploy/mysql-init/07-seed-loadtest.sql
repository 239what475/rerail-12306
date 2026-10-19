-- 幂等清理
DELETE IGNORE FROM `12306_user_0`.`t_user_0` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_0`.`t_user_1` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_0`.`t_user_2` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_0`.`t_user_3` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_0`.`t_user_4` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_0`.`t_user_5` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_0`.`t_user_6` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_0`.`t_user_7` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_0`.`t_user_8` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_0`.`t_user_9` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_0`.`t_user_10` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_0`.`t_user_11` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_0`.`t_user_12` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_0`.`t_user_13` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_0`.`t_user_14` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_0`.`t_user_15` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_1`.`t_user_16` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_1`.`t_user_17` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_1`.`t_user_18` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_1`.`t_user_19` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_1`.`t_user_20` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_1`.`t_user_21` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_1`.`t_user_22` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_1`.`t_user_23` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_1`.`t_user_24` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_1`.`t_user_25` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_1`.`t_user_26` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_1`.`t_user_27` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_1`.`t_user_28` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_1`.`t_user_29` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_1`.`t_user_30` WHERE `id` >= 3000000000000000000;
DELETE IGNORE FROM `12306_user_1`.`t_user_31` WHERE `id` >= 3000000000000000000;

INSERT INTO `12306_user_0`.`t_user_6` (`id`,`username`,`password`,`real_name`,`region`,`id_type`,`id_card`,`phone`,`telephone`,`mail`,`user_type`,`verify_status`,`post_code`,`address`,`create_time`,`update_time`,`del_flag`) VALUES
(3000000000000000050,'agent050','12345678','agent050','0',0,'110101199001010509','15900000050','','agent050@rerail.dev',0,1,'','',NOW(),NOW(),0);

INSERT INTO `12306_user_0`.`t_user_7` (`id`,`username`,`password`,`real_name`,`region`,`id_type`,`id_card`,`phone`,`telephone`,`mail`,`user_type`,`verify_status`,`post_code`,`address`,`create_time`,`update_time`,`del_flag`) VALUES
(3000000000000000040,'agent040','12345678','agent040','0',0,'110101199001010402','15900000040','','agent040@rerail.dev',0,1,'','',NOW(),NOW(),0);

INSERT INTO `12306_user_0`.`t_user_8` (`id`,`username`,`password`,`real_name`,`region`,`id_type`,`id_card`,`phone`,`telephone`,`mail`,`user_type`,`verify_status`,`post_code`,`address`,`create_time`,`update_time`,`del_flag`) VALUES
(3000000000000000030,'agent030','12345678','agent030','0',0,'110101199001010306','15900000030','','agent030@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000041,'agent041','12345678','agent041','0',0,'110101199001010410','15900000041','','agent041@rerail.dev',0,1,'','',NOW(),NOW(),0);

INSERT INTO `12306_user_0`.`t_user_9` (`id`,`username`,`password`,`real_name`,`region`,`id_type`,`id_card`,`phone`,`telephone`,`mail`,`user_type`,`verify_status`,`post_code`,`address`,`create_time`,`update_time`,`del_flag`) VALUES
(3000000000000000020,'agent020','12345678','agent020','0',0,'11010119900101020X','15900000020','','agent020@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000031,'agent031','12345678','agent031','0',0,'110101199001010314','15900000031','','agent031@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000042,'agent042','12345678','agent042','0',0,'110101199001010429','15900000042','','agent042@rerail.dev',0,1,'','',NOW(),NOW(),0);

INSERT INTO `12306_user_0`.`t_user_10` (`id`,`username`,`password`,`real_name`,`region`,`id_type`,`id_card`,`phone`,`telephone`,`mail`,`user_type`,`verify_status`,`post_code`,`address`,`create_time`,`update_time`,`del_flag`) VALUES
(3000000000000000010,'agent010','12345678','agent010','0',0,'110101199001010103','15900000010','','agent010@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000021,'agent021','12345678','agent021','0',0,'110101199001010218','15900000021','','agent021@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000032,'agent032','12345678','agent032','0',0,'110101199001010322','15900000032','','agent032@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000043,'agent043','12345678','agent043','0',0,'110101199001010437','15900000043','','agent043@rerail.dev',0,1,'','',NOW(),NOW(),0);

INSERT INTO `12306_user_0`.`t_user_11` (`id`,`username`,`password`,`real_name`,`region`,`id_type`,`id_card`,`phone`,`telephone`,`mail`,`user_type`,`verify_status`,`post_code`,`address`,`create_time`,`update_time`,`del_flag`) VALUES
(3000000000000000011,'agent011','12345678','agent011','0',0,'110101199001010111','15900000011','','agent011@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000022,'agent022','12345678','agent022','0',0,'110101199001010226','15900000022','','agent022@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000033,'agent033','12345678','agent033','0',0,'110101199001010330','15900000033','','agent033@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000044,'agent044','12345678','agent044','0',0,'110101199001010445','15900000044','','agent044@rerail.dev',0,1,'','',NOW(),NOW(),0);

INSERT INTO `12306_user_0`.`t_user_12` (`id`,`username`,`password`,`real_name`,`region`,`id_type`,`id_card`,`phone`,`telephone`,`mail`,`user_type`,`verify_status`,`post_code`,`address`,`create_time`,`update_time`,`del_flag`) VALUES
(3000000000000000001,'agent001','12345678','agent001','0',0,'110101199001010015','15900000001','','agent001@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000012,'agent012','12345678','agent012','0',0,'11010119900101012X','15900000012','','agent012@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000023,'agent023','12345678','agent023','0',0,'110101199001010234','15900000023','','agent023@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000034,'agent034','12345678','agent034','0',0,'110101199001010349','15900000034','','agent034@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000045,'agent045','12345678','agent045','0',0,'110101199001010453','15900000045','','agent045@rerail.dev',0,1,'','',NOW(),NOW(),0);

INSERT INTO `12306_user_0`.`t_user_13` (`id`,`username`,`password`,`real_name`,`region`,`id_type`,`id_card`,`phone`,`telephone`,`mail`,`user_type`,`verify_status`,`post_code`,`address`,`create_time`,`update_time`,`del_flag`) VALUES
(3000000000000000002,'agent002','12345678','agent002','0',0,'110101199001010023','15900000002','','agent002@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000013,'agent013','12345678','agent013','0',0,'110101199001010138','15900000013','','agent013@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000024,'agent024','12345678','agent024','0',0,'110101199001010242','15900000024','','agent024@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000035,'agent035','12345678','agent035','0',0,'110101199001010357','15900000035','','agent035@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000046,'agent046','12345678','agent046','0',0,'110101199001010461','15900000046','','agent046@rerail.dev',0,1,'','',NOW(),NOW(),0);

INSERT INTO `12306_user_0`.`t_user_14` (`id`,`username`,`password`,`real_name`,`region`,`id_type`,`id_card`,`phone`,`telephone`,`mail`,`user_type`,`verify_status`,`post_code`,`address`,`create_time`,`update_time`,`del_flag`) VALUES
(3000000000000000003,'agent003','12345678','agent003','0',0,'110101199001010031','15900000003','','agent003@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000014,'agent014','12345678','agent014','0',0,'110101199001010146','15900000014','','agent014@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000025,'agent025','12345678','agent025','0',0,'110101199001010250','15900000025','','agent025@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000036,'agent036','12345678','agent036','0',0,'110101199001010365','15900000036','','agent036@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000047,'agent047','12345678','agent047','0',0,'11010119900101047X','15900000047','','agent047@rerail.dev',0,1,'','',NOW(),NOW(),0);

INSERT INTO `12306_user_0`.`t_user_15` (`id`,`username`,`password`,`real_name`,`region`,`id_type`,`id_card`,`phone`,`telephone`,`mail`,`user_type`,`verify_status`,`post_code`,`address`,`create_time`,`update_time`,`del_flag`) VALUES
(3000000000000000004,'agent004','12345678','agent004','0',0,'11010119900101004X','15900000004','','agent004@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000015,'agent015','12345678','agent015','0',0,'110101199001010154','15900000015','','agent015@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000026,'agent026','12345678','agent026','0',0,'110101199001010269','15900000026','','agent026@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000037,'agent037','12345678','agent037','0',0,'110101199001010373','15900000037','','agent037@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000048,'agent048','12345678','agent048','0',0,'110101199001010488','15900000048','','agent048@rerail.dev',0,1,'','',NOW(),NOW(),0);

INSERT INTO `12306_user_1`.`t_user_16` (`id`,`username`,`password`,`real_name`,`region`,`id_type`,`id_card`,`phone`,`telephone`,`mail`,`user_type`,`verify_status`,`post_code`,`address`,`create_time`,`update_time`,`del_flag`) VALUES
(3000000000000000005,'agent005','12345678','agent005','0',0,'110101199001010058','15900000005','','agent005@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000016,'agent016','12345678','agent016','0',0,'110101199001010162','15900000016','','agent016@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000027,'agent027','12345678','agent027','0',0,'110101199001010277','15900000027','','agent027@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000038,'agent038','12345678','agent038','0',0,'110101199001010381','15900000038','','agent038@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000049,'agent049','12345678','agent049','0',0,'110101199001010496','15900000049','','agent049@rerail.dev',0,1,'','',NOW(),NOW(),0);

INSERT INTO `12306_user_1`.`t_user_17` (`id`,`username`,`password`,`real_name`,`region`,`id_type`,`id_card`,`phone`,`telephone`,`mail`,`user_type`,`verify_status`,`post_code`,`address`,`create_time`,`update_time`,`del_flag`) VALUES
(3000000000000000006,'agent006','12345678','agent006','0',0,'110101199001010066','15900000006','','agent006@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000017,'agent017','12345678','agent017','0',0,'110101199001010170','15900000017','','agent017@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000028,'agent028','12345678','agent028','0',0,'110101199001010285','15900000028','','agent028@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000039,'agent039','12345678','agent039','0',0,'11010119900101039X','15900000039','','agent039@rerail.dev',0,1,'','',NOW(),NOW(),0);

INSERT INTO `12306_user_1`.`t_user_18` (`id`,`username`,`password`,`real_name`,`region`,`id_type`,`id_card`,`phone`,`telephone`,`mail`,`user_type`,`verify_status`,`post_code`,`address`,`create_time`,`update_time`,`del_flag`) VALUES
(3000000000000000007,'agent007','12345678','agent007','0',0,'110101199001010074','15900000007','','agent007@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000018,'agent018','12345678','agent018','0',0,'110101199001010189','15900000018','','agent018@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000029,'agent029','12345678','agent029','0',0,'110101199001010293','15900000029','','agent029@rerail.dev',0,1,'','',NOW(),NOW(),0);

INSERT INTO `12306_user_1`.`t_user_19` (`id`,`username`,`password`,`real_name`,`region`,`id_type`,`id_card`,`phone`,`telephone`,`mail`,`user_type`,`verify_status`,`post_code`,`address`,`create_time`,`update_time`,`del_flag`) VALUES
(3000000000000000008,'agent008','12345678','agent008','0',0,'110101199001010082','15900000008','','agent008@rerail.dev',0,1,'','',NOW(),NOW(),0),
(3000000000000000019,'agent019','12345678','agent019','0',0,'110101199001010197','15900000019','','agent019@rerail.dev',0,1,'','',NOW(),NOW(),0);

INSERT INTO `12306_user_1`.`t_user_20` (`id`,`username`,`password`,`real_name`,`region`,`id_type`,`id_card`,`phone`,`telephone`,`mail`,`user_type`,`verify_status`,`post_code`,`address`,`create_time`,`update_time`,`del_flag`) VALUES
(3000000000000000009,'agent009','12345678','agent009','0',0,'110101199001010090','15900000009','','agent009@rerail.dev',0,1,'','',NOW(),NOW(),0);

-- 50 agents (passengers via API due to ShardingSphere encryption)
