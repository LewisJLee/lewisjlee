#!/bin/sh

mysql -ulumen -pjgkim@udid.co.kr -e "use lumen;

SELECT 
good.GoodNum as '상품번호', 
if (good.CateNum != 0, good.CateNum, '') as '카테고리번호',
good.GoodName '상품이름',
concat(good.SubtitleColor,'/',good.Subtitle) '상품설명',
#GC.goodcontent '상품상세',
#GC.goodcontent2 '상품상세2',
good.GoodPrice '상품가격',
good.DisplayPrice '이전가격',
good.BasisPrice '공급가',
good.Inven '재고',
concat('https://',good.Siteid,'.shop.bloppay.co.kr/img/g/',good.Siteid,'/', (select GoodImg from tblGoodsImg img where img.GoodNum = good.GoodNum)) as '이미지',
(case good.IsDeliveryPrice
	when ( good.IsDeliveryPrice = 0 and good.IsDelivery = 1 ) then 'N'
	else 'Y' end
) as '배송 유무',
concat
(
	(
	case good.isDeliveryPrice 
	when (good.IsDeliveryPrice = 1 and good.IsDelivery = 0 and good.BsFree != 0) 
	then 'Y'
	else 'N'
	end
	), '/', good.shipSubNum) as '배송비설정',
if (good.IsDelivery = 1 and good.IsDeliveryPrice = 1, concat(good.EdeliBprice,'/',good.EdeliFprice),'') as '개별배송비 설정',
if (good.IsDelivery != 0 and good.addShip = 1, 'Y' ,'') as '지역배송비',
if (good.gBindNum != 0 , good.gBindNum, '') as '묶음상품',
if (good.BuyDcInfo != '', 
	concat(
		SUBSTRING_INDEX(good.BuyDcInfo ,'|', 1), '/', 
		if (SUBSTRING_INDEX(good.BuyDcInfo ,'|', -1) = 'gae' ,'개','원'), 
			'/', 
			SUBSTRING_INDEX(SUBSTRING_INDEX(good.BuyDcInfo ,'|', -2),'|',1)
	),
'') as '구매혜택',
if (good.perLimitCount != '0|0' , replace(good.perLimitCount, '|','/'), '') as '구매조건',
good.Orign '원산지',
good.Maker '제조사',
if (good.isShow = 1 , 'Y','N') as '전시여부',
if (good.isRecommend = 1 , 'Y','N') as '메인진열',
if (good.isEvent = 1,'Y','N') as '사은품여부',
if (good.goodsft = 1 ,'Y','N') as 'APP최상단위치',
if (enablePayMethod & 4 = 4 ,'Y', 'N') as '결제수단(핸드폰)',
if (enablePayMethod & 2 = 2 ,'Y', 'N') as '결제수단(토스)',
if (enablePayMethod & 8 = 8 ,'Y', 'N') as '결제수단(계좌이체)',
if (enablePayMethod & 16 = 16 ,'Y', 'N') as '결제수단(가상계좌)',
if (enablePayMethod & 128 = 128 ,'Y', 'N') as '결제수단(무통장입금)',
if (enablePayMethod & 32 = 32 ,'Y', 'N') as '결제수단(대리결제)',
if (enablePayMethod & 1024 = 1024 ,'Y', 'N') as '결제수단(카카오페이)',
if (enablePayMethod & 2048 = 2048 ,'Y', 'N') as '결제수단(네이버페이)',
if (enablePayMethod & 64 = 64 ,'Y', 'N') as '쇼핑몰동시적용여부',
good.GoodsCode as '상품코드',
good.SupplyUserId as '공급업체',
if (good.CusNum =1 ,'Y', 'N') as '개인통관번호유무',
good.Tag as '검색키워드',
if (good.isSmUse = 2 ,'N', 'Y') as '적립금사용',
normaloption.normalOption as '일반옵션 (옵션명||옵션값||금액)',
addoption.addoption as '추가상품 (옵션명||옵션값||금액)',
inputoption.inputoption as '입력옵션 (옵션명||옵션값||금액)',
invenoption.invenoption as '재고옵션 (옵션명1||옵션명2||옵션명3||옵션명4||옵션값1||옵션값2||옵션값3||옵션값4)',
invenoption.OptionInven as '옵션재고',
invenoption.OptionSourcePrice as '옵션공급가',
invenoption.optionSet '옵션 가격 설정',
invenoption.optionUseSet '옵션 사용 유무'

FROM tblGoods as good
# normaloption info start
left outer join (
	select g.GoodNum, 
	GROUP_CONCAT(
		concat(
			ifnull(gno.NoTitle, ''), 
			'||', 
			ifnull(gnol.NoValue, ''), 
			'||', 
			ifnull(gnol.NoPrice, '')
		)
	) as 'normalOption'
	from tblGoods as g
	left join tblGoodsNormalOption as gno on g.GoodNum = gno.GoodNum
	left join tblGoodsNormalOptionList as gnol on gno.GoodsNormalOptionNum = gnol.GoodsNormalOptionNum
	where 
	g.Siteid = 'SITEID' and 
	gno.GoodsNormalOptionNum is not null and
	gno.NoRequire = 1
	group by g.GoodNum
) as normaloption on good.GoodNum = normaloption.GoodNum
# normaloption info end

/*LEFT OUTER JOIN (
SELECT g.GoodNum, gc.GoodContent AS 'goodcontent', gc.GoodContent2 AS 'goodcontent2' FROM tblGoods AS g
LEFT JOIN tblGoodsContent AS gc on g.GoodNum = gc.GoodNum
WHERE g.Siteid = 'SITEID') AS GC ON good.GoodNum = GC.GoodNum*/

# addoption info start
left outer join (
	select g.GoodNum, 
	GROUP_CONCAT(
		concat(
			ifnull(gno.NoTitle, ''), 
			'||', 
			ifnull(gnol.NoValue, ''), 
			'||', 
			ifnull(gnol.NoPrice, '')
		)
	) as 'addoption'
	from tblGoods as g
	left join tblGoodsNormalOption as gno on g.GoodNum = gno.GoodNum
	left join tblGoodsNormalOptionList as gnol on gno.GoodsNormalOptionNum = gnol.GoodsNormalOptionNum
	where 
	g.Siteid = 'SITEID' and 
	gno.GoodsNormalOptionNum is not null and
	gno.NoRequire = 0
	group by g.GoodNum
) as addoption on good.GoodNum = addoption.GoodNum
# addoption info end

# inputoption info start
left outer join (
	select g.GoodNum, 
	GROUP_CONCAT(concat(gio.IoTitle, '||', gio.IoPrice)) as 'inputoption'
	from tblGoods as g
	left join tblGoodsInputOption gio on g.GoodNum = gio.GoodNum
	where 
	g.Siteid = 'SITEID' and
	gio.IoTitle is not null
	group by g.GoodNum
) as inputoption on inputoption.GoodNum = good.GoodNum
# inputoption info end

# invenoption info start
left outer join (
	select g.GoodNum, 
	GROUP_CONCAT(
		concat(
			ifnull(goi.OptionTitle1, ''), 
			'||', 
			ifnull(goi.OptionTitle2, ''), 
			'||',
			ifnull(goi.OptionTitle3, ''), 
			'||',
			ifnull(goi.OptionTitle4, ''), 
			'||',
			ifnull(goil.OptionValue1, ''), 
			'||',
			ifnull(goil.OptionValue2, ''), 
			'||',
			ifnull(goil.OptionValue3, ''), 
			'||',
			ifnull(goil.OptionValue4, ''), 
			'||'
		)
	) as 'invenoption',
	goil.OptionInven, 
	goil.OptionSourcePrice, 
	if (goil.OptionPrice = 0, '옵션가', '판매가') as optionSet, 
	if (goil.OptionShow = 0, '미사용', '사용') as optionUseSet
	from tblGoods as g
	left join tblGoodsOptionInven as goi on g.GoodNum = goi.GoodNum
	left join tblGoodsOptionInvenList as goil on goi.GoodsOptionInvenNum = goil.GoodsOptionInvenNum
	where 
	g.Siteid = 'SITEID' and
	goi.OptionTitle1 is not null
	group by g.GoodNum
) as invenoption on good.GoodNum = invenoption.GoodNum
# invenoption info end

where good.siteid = 'SITEID';"
