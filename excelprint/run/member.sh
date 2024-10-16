#!/bin/sh

mysql -ulumen -pjgkim@udid.co.kr -e "use lumen;

SELECT 
mememail '아이디',
memsubemail '이메일',
memcheckemail '이메일 발신 허용',
memscreen '회원명',
CONCAT(memphone1,\"-\",memphone2,\"-\",memphone3) '전화번호',
memchecksms 'SMS 발신 허용',
memzip '우편번호',
CONCAT(memaddr1,\" \",memaddr2) '주소',
memregistdate '등록일',
orderprice '구매금액',
savedmoney '적립금',
adminmemo '관리자 메모',
memnickname '닉네임'
FROM tblMember
WHERE siteid ='SITEID'
AND ismember=1;"
