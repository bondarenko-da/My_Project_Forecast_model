----------------------------------------------------- ПОСТАНОВКА ЗАДАЧИ -----------------------------------------------------------------------
в связи с тем, что моделью машинного обучения мы не можем добиться желаемого качества на старте продаж (когда еще нет фактических продаж за прошлые 4 недели, которые дают высокую значимость), 
а также для потокового инвентаря, то договорились попробовать сделать простую модель только на истории кривых продаж прошлых лет и посмотреть на сезоне SS20 насколько такая модель нас устроит. 
Если она будет лучше в эти периоды, чем текущая боевая, то ее сделаем боевой версией на указанные периоды и потом может будем улучшать до более сложных вариантов.. ?

1.	Создание блока цветомодель/магазин /неделя, по которым нужен прогноз.
    1)	Берем магазины только Супер + Гипер + ПРО Россия + Беларусь +Казахстан.
    2)	Одежда +обувь+ инвентарь+тренажеры.
    3)	Взять плановый лимит на модель/магазин на сезон (SS20)-оставить только строки с ненулевым плановым лимитом.
    4)	Период с 1 ноября по 31 августа.
    5)	Оставить только недели от Intake date до Exit date для цветомодели (в рамках периода из пункта 4)
        - то есть, начало периода =макс( 1 ноября 2019 , Intake date), конец периода=мин(31 августа, Exit date)
    ?	Получаешь матрицу, на которую нам нужно рассчитать прогноз ( цветомодель/магазин /неделя)

2.	Матрица по историческим кол-вам моделей/магазинов в группе.
    a.	Для каждого сезона SS (за последние три года: SS19 , SS18, SS17) считаешь сколько моделей/магазинов должны были быть представлены в продажах на конкретной неделе: 
    так же, как и в блоке предыдущем, составляешь матрицу магазин/модель/неделя 
    
-Давай в этом пункте посчитаем по фактическим остаткам и продажам понедельно: 
-для каждой недели берешь остаток на воскресенье +продажи за неделю для каждого магазина=> считаешь число уникальных цм
-Цветомодели только из плановых лимитов соответствующего сезона ( чтобы случайно не захватить зимние модели с похожими товарными свойствами). 
-Это нужно для нормирование продаж (чтобы исключить искривление продаж из-за более ранних /поздних дат вводов, OOS и разной кластеризации одного и того же магазина в сезоне).

    b.	Начало периода на модель /магазин= первая ненулевая дата с ненулевым значением (остаток на конец недели + продажа за неделю) после 1 ноября * 
    c.	Конец периода = последняя дата с ненулевым значением (остаток на конец недели + продажа за неделю) до 31 августа
    Эту матрицу схлопываешь до уровня регион/ свойства товара ( св1 , св3 , св5 , с6 6 , возраст , СТМ/не СТМ ), неделя , количество получившихся строк (моделей/магазинов)
    *Не забыть, что нельзя суммировать с пустыми значениями => вначале все пустые строки заменить на 0. Ну или вначале считаешь минимальную дату с ненулевым остаток после 1 ноября, 
    затем минимальную  дату с продажей ненулевой после 1 ноября => далее берешь минимум из этих двух дат – это и будет первая дата с ненулевым значением (остаток на конец недели + продажа за неделю)
    А значение «последняя дата с ненулевым значением (остаток на конец недели + продажа за неделю) до 31 августа» := берешь максимальную дату с ненулевым остатков до 31 августа, 
    максимальную дату с ненулевой продажей до 31 августа => максимум из этих двух и есть последняя дата с ненулевым значением (остаток на конец недели + продажа за неделю)

3.	Блок по истории продаж за 3 года (свойства товара /регион/неделя. Все недели с 1 ноября по 31 августа)
    i.	Берешь товар  только из плановых лимитов сезонов SS.
    ii.	Считаешь за три года продажи  понедельные на уровне свойств товара св1 , св3 , св5 , св6 , возраст , СТМ/не СТМ , регион магазина, неделя . Показатель : продажи штуки суммарные.  
    Какие недели включаешь: недели берешь из матрицы блока 2 .
    iii.	Считаешь за три года продажи понедельные нормированные на уровне свойств товара св1 , св3 , св5 , св6 , возраст , СТМ/не СТМ , регион магазина, неделя . 
    Показатель : продажи штуки суммарные/ (кол-во магазинов*кол-во моделей –из матрицы из блока 2)
- Недели только с ненулевым знаменателем.
    ?	Далее усредняешь за три года значения. Получаешь таблицу вида свойства товара/ регион/ неделя/ продажи средние обычные/ продажи средние нормированные.
    *При усреднении важно учитывать , что если какой-то недели не было в одном-двум из трех годах, то и усреднять с нулем не надо. То есть:
    продажи средние обычные= продажи суммарные на эту неделю за 3 года/ кол-во лет с ненулевыми  продажами
    продажи средние нормированные= продажи суммарные на эту неделю за 3 года/ сумма( моделей/магазинов за 3 года на эту неделю)

4.	Итоговый прогноз по неделям:
    a.	К первому блоку подтягиваешь данные третьего блока ( связка по свойствам товара + регион +неделя)=> получаешь таблицу модель/ магазин/ неделя / свойства товара/ регион/ продажи средние обычные/ продажи средние нормированные
    b.	Если есть не подтянувшиеся строки= > проверка подтянулось ли для пары модель/магазин хотя бы на одну неделю. Если подтянулось на часть недель => на оставшиеся недели взять среднее по подтянувшимся неделям.
    c.	Если не подтянулось для пары модель/магазин ни для одной недели ( то есть, за прошлые годы товар с такими свойствами не продавался в регионе) =>последовательно пробуем подтянуть более высокие уровни:
    i.	св1 , св5 , св6 , возраст, регион
    ii.	св1 , cв5 , св6 , возраст
    iii.	св1 , св5 , св6 
    iv.	св1 , св5
    v.	св1 , св3
    vi.	св1 –на этом этапе точно всё подтянется, так как св1 у нас из года в год неизменны (одежда, обувь, инвентарь)
    *Записать на строку уровень подтяжки данных: например 0 – ничего не подтягивали, 1 –подтянули только на некоторые недели, 2 – подтянули по св1 , св5 , св6 , возраст, регион, 3 – подтянули по св1 , cв5 , св6 , возраст
    -потом при оценке качества эти группы можно будет выделить.
    d.	Считаешь доли по неделям: доля продаж недели (отдельно для нормированной продажи, отдельно для ненормированной) к суммарным продажам по всем неделям для данной цм/магазина
    e.	Добавляешь суммарный плановый лимит в штуках на модель /магазин (одно значение по всем неделям) и домножаешь его на процент из прошлого пункта 
    (один столбец делаешь с домножением на нормированное значение, второй на ненормированное) => получаешь два прогноза
------------
Проверка качества –на первых 6 неделям после Intake, но даты Intake давай возьмем только до 15 февраля (потом карантин и некорректно считать).. 
Сравнить с прогнозной моделью Володи с шагом 1 неделя и две недели. Отдельно проверку сделать только для цм, участвующих в ПРК, 

Если там будет не очень качество, то еще следущий фильтр: только для
Магазинов, которые были в прошлом году и моделей , свойства которых продавались в прошлом году.
--------------
На выходе нужна таблица:
Модель/магазин/неделя/прогноз в штуках

--/////////////////////////////////////////////////////////// РЕШЕНИЕ //////////////////////////////////////////////////////////////////////////////////////////////////////
-- SELECT * FROM Shops_mod.t_forecast_stylecolor
--SELECT * FROM SHOPS_MOD.T_FORECAST_STORES 
-- where st = 365

-- 1.	Создание блока цветомодель/магазин /неделя, по которым нужен прогноз.
-- Создаём пул прогнозируемых объектов цветомодель-магазин на основе плановых лимитов
--truncate table fcst_model_store_pull;
--commit;
--insert into fcst_model_store_pull
DROP TABLE fcst_model_store_pull PURGE;
CREATE TABLE fcst_model_store_pull AS
select /*+ materialize */ pl.stylecolorid, pl.storeid, pl.collection as season, 
        trunc(pl.intakedate) intakedate, trunc(pl.exitdate) exitdate, 
        trunc(greatest(pl.intakedate, s.first_season_d)) as date_model_beg,
        trunc(least(pl.exitdate, s.last_season_d)) as date_model_end,
        s.first_season_d, s.last_season_d, 
        sc.waregroup, sc.warecategory, sc.waretradegroup, sc.waretradesubgroup, sc.waretype, sc.age1,
        --sc.nsize,
        --count(distinct pl.STOREID) over(partition by pl.stylecolorid, pl.collection) n_store,
        st.region, st.project,
        pl.qtypl,
        pl.qtyupa
from shops_mod.t_forecast_plan_limit pl 
        join SHOPS_MOD.T_FORECAST_STORES st ON (pl.STOREID = st.STOREID)
        join Shops_mod.t_forecast_stylecolor sc on (pl.stylecolorid = sc.stylecolorid)
        left join (select distinct p.season_sales_short season, trunc(add_months(p.last_season_d, -9), 'MM') first_season_d, p.last_season_d 
                    from Shops_Mod.T_Forecast_Week p) s on s.season = pl.collection
where 1=1
        and pl.collection in ('SS20')
        and pl.qtypl > 0 
        and st.id_country_ref in (13, /*Россия*/ 14, /*Белоруссия*/965 /*Казахстан*/)
        and st.project in ('СМ-Супер', 'СМ-Гипер','СМ-PRO') 
        and sc.waregroup in ('Одежда','Обувь','Инвентарь','Тренажеры')
        and sc.warecategory not in ('Форма для персонала' /*, 'Командные виды спорта'*/)
 ;
 select sum(qtypl) from fcst_model_store_pull;
 -- проверка на задвоения
 SELECT stylecolorid, storeid, count(*)
 FROM fcst_model_store_pull
 group by stylecolorid, storeid
 having count(*) > 1;
 ;
-- Добавляем недели в матрицу модель-магазин
DROP TABLE fcst_model_store_weeks PURGE;
create table fcst_model_store_weeks as
SELECT pl.*, s.date_, s.weekid, s.weeknumber
FROM fcst_model_store_pull pl, Shops_Mod.T_Forecast_Week s
--where STYLECOLORID = 'RCS090W_CLB-RSPB' and STOREID = 3004 -- для проверки
where s.n_day_week = 7
and s.date_ between pl.date_model_beg and pl.DATE_MODEL_END
;
select * from fcst_model_store_weeks where  date_model_beg is null
;
-- 2.	Матрица по историческим кол-вам моделей/магазинов в группе.
----------------------------------------- Создаём общую таблиду модель-магазин-неделя с Продажами, Остатками -----------------------------------
select * from Shops_mod.t_forecast_rest
select * from shops_mod.t_forecast_weekly_clean_bills
select * from Shops_Mod.T_Forecast_Week

--truncate table sales_rests_hist;
--commit;
--insert into sales_rests_hist
DROP TABLE sales_rests_hist PURGE;
CREATE TABLE sales_rests_hist AS
select 
coalesce(r.date_,s.date_) date_
,'SS19' as season
,coalesce(s.stylecolorid, r.model) as stylecolorid
,coalesce(s.storeid, r.storeid) as storeid
,nvl(r.amount,0) as rests_qty
,nvl(s.sales_qty,0) as sales_qty
from Shops_mod.t_forecast_rest r  -- Rests (Остатки)
    full join (select /*+ materialize */  a.storeid, a.stylecolorid, a.weekid, p.date_,
                sum(a.qty)  sales_qty
                from shops_mod.t_forecast_weekly_clean_bills a
                    join Shops_Mod.T_Forecast_Week p on (a.weekid = p.weekid and p.n_day_week = 7 and p.date_ between date'2018-11-01' and date'2019-08-31')
                group by a.storeid, a.stylecolorid, a.weekid, p.date_
              ) s on (r.storeid  = s.storeid and r.model = s.stylecolorid and r.date_ = s.date_) -- Sales (Продажи)
where r.date_ between date'2018-11-01' and date'2019-08-31'
union 
select 
coalesce(r.date_,s.date_) date_
,'SS18' as season
,coalesce(s.stylecolorid, r.model) as stylecolorid
,coalesce(s.storeid, r.storeid) as storeid
,nvl(r.amount,0) as rests_qty
,nvl(s.sales_qty,0) as sales_qty
from Shops_mod.t_forecast_rest r  -- Rests (Остатки)
    full join (select /*+ materialize */  a.storeid, a.stylecolorid, a.weekid, p.date_,
                sum(a.qty)  sales_qty
                from shops_mod.t_forecast_weekly_clean_bills a
                    join Shops_Mod.T_Forecast_Week p on (a.weekid = p.weekid and p.n_day_week = 7 and p.date_ between date'2017-11-01' and date'2018-08-31')
                group by a.storeid, a.stylecolorid, a.weekid, p.date_
              ) s on (r.storeid  = s.storeid and r.model = s.stylecolorid and r.date_ = s.date_) -- Sales (Продажи)
where r.date_ between date'2017-11-01' and date'2018-08-31'
union 
select 
coalesce(r.date_,s.date_) date_
,'SS17' as season
,coalesce(s.stylecolorid, r.model) as stylecolorid
,coalesce(s.storeid, r.storeid) as storeid
,nvl(r.amount,0) as rests_qty
,nvl(s.sales_qty,0) as sales_qty
from Shops_mod.t_forecast_rest r  -- Rests (Остатки)
    full join (select /*+ materialize */  a.storeid, a.stylecolorid, a.weekid, p.date_,
                sum(a.qty)  sales_qty
                from shops_mod.t_forecast_weekly_clean_bills a
                    join Shops_Mod.T_Forecast_Week p on (a.weekid = p.weekid and p.n_day_week = 7 and p.date_ between date'2016-11-01' and date'2017-08-31')
                group by a.storeid, a.stylecolorid, a.weekid, p.date_
              ) s on (r.storeid  = s.storeid and r.model = s.stylecolorid and r.date_ = s.date_) -- Sales (Продажи)
where r.date_ between date'2016-11-01' and date'2017-08-31'
;
--select count(*) from sales_rests_hist;
select * from sales_rests_hist where stylecolorid in ('11227297N0H-GRN') and storeid = 3150 order by date_;

-- Добавляем свойства моделей и оставляем только модели, которые были в плановом лимите сезонов SS
--truncate table sales_rests_hist2;
--commit;
--insert into sales_rests_hist2
DROP TABLE sales_rests_hist2 PURGE;
CREATE TABLE sales_rests_hist2 AS
select h.*
,sc.waregroup, sc.warecategory, sc.waretradegroup, sc.waretradesubgroup, sc.waretype, sc.age1
,st.region, st.project
from sales_rests_hist h
      join (select distinct stylecolorid, storeid from shops_mod.t_forecast_plan_limit where qtypl > 0 and collection in ('SS17','SS18','SS19')) pl on (h.stylecolorid = pl.stylecolorid and h.STOREID = pl.storeid)
      join SHOPS_MOD.T_FORECAST_STORES st ON (h.STOREID = st.STOREID)
      join Shops_mod.t_forecast_stylecolor sc on (h.stylecolorid = sc.stylecolorid)
where 1=1
        --and h.stylecolorid is not null
        and st.id_country_ref in (13, /*Россия*/ 14, /*Белоруссия*/965 /*Казахстан*/)
        and st.project in ('СМ-Супер', 'СМ-Гипер','СМ-PRO') 
        and sc.waregroup in ('Одежда','Обувь','Инвентарь','Тренажеры')
        and sc.warecategory not in ('Форма для персонала' /*, 'Командные виды спорта'*/)
;
--select * from sales_rests_hist2;

-- 3. Блок по истории продаж за 3 года (свойства товара /регион/неделя. Все недели с 1 ноября по 31 августа)
-- Агрегируем данные по свойствам товара и регионам
--truncate table sales_rests_hist_agg;
--commit;
--insert into sales_rests_hist_agg
DROP TABLE sales_rests_hist_agg PURGE;
CREATE TABLE sales_rests_hist_agg AS
select h.date_, h.season, p.weeknumber
,waregroup, warecategory, waretradegroup, waretradesubgroup, waretype, age1, region
,count(distinct stylecolorid) as stylecolorid_qty
,count(distinct storeid) as storeid_qty
,sum(sales_qty) as sales_qty
,sum(sales_qty)/(count(distinct stylecolorid)*count(distinct storeid)) as sales_normirov
from sales_rests_hist2 h
    join Shops_Mod.T_Forecast_Week p on (h.date_ = p.date_)
group by h.date_, h.season, p.weeknumber, waregroup, warecategory, waretradegroup, waretradesubgroup, waretype, age1, region
;
--select * from sales_rests_hist_agg;
--select count(*) from sales_rests_hist_agg;
-- Сворачиваем три года в один. Берём среднюю по ненулевым годам
DROP TABLE sales_rests_agg_avg PURGE;
CREATE TABLE sales_rests_agg_avg AS
select weeknumber
,waregroup, warecategory, waretradegroup, waretradesubgroup, waretype, age1, region
,avg(sales_qty) sales_qty
,avg(sales_normirov) sales_normirov
from sales_rests_hist_agg
where sales_qty > 0 
group by weeknumber,waregroup, warecategory, waretradegroup, waretradesubgroup, waretype, age1, region
;
-- 4.	Итоговый прогноз по неделям
-- Соединяем матрицу модель-магазин-неделя, которую нам надо спрогнозировать с историческими значениями
DROP TABLE fcst_model_store_weeks_sal PURGE;
CREATE TABLE fcst_model_store_weeks_sal AS
select f.*, a.sales_qty, a.sales_normirov 
from fcst_model_store_weeks f
    left join sales_rests_agg_avg a on (f.weeknumber = a.weeknumber and f.waregroup = a.waregroup and f.warecategory = a.warecategory and f.waretradegroup = a.waretradegroup and f.waretradesubgroup = a.waretradesubgroup and f.waretype = a.waretype and f.age1 = a.age1 and f.region = a.region)
--where f.STYLECOLORID in ('S19EOUOT017OUT-74') and f.storeid = 328
--order by f.weeknumber
;
drop table fcst_model_store_weeks_sal_avg purge;
CREATE TABLE fcst_model_store_weeks_sal_avg AS
select f.*
,avg(sales_qty) over(partition by stylecolorid, storeid) as avg_sales_qty
,avg(sales_normirov) over(partition by stylecolorid, storeid) as avg_sales_normirov
from fcst_model_store_weeks_sal f
where weeknumber != 35
-- and sales_qty is not null 

;
DROP TABLE fcst_model_store_weeks_sal20 PURGE;
CREATE TABLE fcst_model_store_weeks_sal20 AS
select s1.*
,case when s1.weeknumber !=35 and s1.sales_qty is null then s2.avg_sales_qty
else s1.sales_qty end as sales_qty_new
,case when s1.weeknumber !=35 and s1.sales_normirov is null then s2.avg_sales_normirov
else s1.sales_normirov end as sales_normirov_new
from fcst_model_store_weeks_sal s1
    left join fcst_model_store_weeks_sal_avg s2 on (s1.STYLECOLORID = s2.STYLECOLORID and s1.storeid = s2.storeid and s1.weeknumber = s2.weeknumber)
;
commit;

DROP TABLE fcst_model_store_weeks_sal2 PURGE;
CREATE TABLE fcst_model_store_weeks_sal2 AS
select s1.*
,case when s1.weeknumber = 35 then s3.sales_qty_new
else s1.sales_qty_new end as sales_qty1
,case when s1.weeknumber = 35 then s3.sales_normirov_new
else s1.sales_normirov_new end as sales_normirov1
from fcst_model_store_weeks_sal20 s1
    left join fcst_model_store_weeks_sal20 s3 on (s1.STYLECOLORID = s3.STYLECOLORID and s1.storeid = s3.storeid and s3.weeknumber = 34)
;
commit;

--c.	Если не подтянулось для пары модель/магазин ни для одной недели ( то есть, за прошлые годы товар с такими свойствами не продавался в регионе) =>последовательно пробуем подтянуть более высокие уровни:
--    i.	св1 , св5 , св6 , возраст, регион
--    ii.	св1 , cв5 , св6 , возраст
--    iii.	св1 , св5 , св6 
--    iv.	св1 , св5
--    v.	св1 , св3
--    vi.	св1 –на этом этапе точно всё подтянется, так как св1 у нас из года в год неизменны (одежда, обувь, инвентарь)
--Св1-waregroup ,
--Св3- warecategory, 
--Св5-waretradegroup, 
--Св6- waretradesubgroup, 
--Возраст- age1  
--СТМ/не СТМ -  waretype

-- i.	св1 , св5 , св6 , возраст, регион
DROP TABLE fcst_model_store_weeks_sal_a1 PURGE;
CREATE TABLE fcst_model_store_weeks_sal_a1 AS
select  waregroup, waretradegroup, waretradesubgroup, age1, region, weeknumber
,avg(sales_qty1) sales_qty1_avg, avg(sales_normirov1) sales_normirov1_avg
from  fcst_model_store_weeks_sal2
group by waregroup,  waretradegroup, waretradesubgroup, age1, region, weeknumber
order by waregroup,  waretradegroup, waretradesubgroup, age1, region, weeknumber
;
DROP TABLE fcst_model_store_weeks_sal3 PURGE;
CREATE TABLE fcst_model_store_weeks_sal3 AS
select f.*, nvl(f.sales_qty1,a.sales_qty1_avg) sales_qty2, nvl(f.sales_normirov1, a.sales_normirov1_avg) sales_normirov2
from fcst_model_store_weeks_sal2 f
    left join fcst_model_store_weeks_sal_a1 a on (f.weeknumber = a.weeknumber and f.waregroup = a.waregroup and f.waretradegroup = a.waretradegroup 
                                                  and f.waretradesubgroup = a.waretradesubgroup and f.age1 = a.age1 and f.region = a.region)
;
--     ii.	св1 , cв5 , св6 , возраст
DROP TABLE fcst_model_store_weeks_sal_a2 PURGE;
CREATE TABLE fcst_model_store_weeks_sal_a2 AS
select  waregroup, waretradegroup, waretradesubgroup, age1, weeknumber
,avg(sales_qty1) sales_qty1_avg, avg(sales_normirov1) sales_normirov1_avg
from  fcst_model_store_weeks_sal3
group by waregroup,  waretradegroup, waretradesubgroup, age1, weeknumber
order by waregroup,  waretradegroup, waretradesubgroup, age1, weeknumber
;
DROP TABLE fcst_model_store_weeks_sal4 PURGE;
CREATE TABLE fcst_model_store_weeks_sal4 AS
select f.*, nvl(f.sales_qty2,a.sales_qty1_avg) sales_qty3, nvl(f.sales_normirov2, a.sales_normirov1_avg) sales_normirov3
from fcst_model_store_weeks_sal3 f
    left join fcst_model_store_weeks_sal_a2 a on (f.weeknumber = a.weeknumber and f.waregroup = a.waregroup and f.waretradegroup = a.waretradegroup 
                                                  and f.waretradesubgroup = a.waretradesubgroup and f.age1 = a.age1)
;
-- iii.	св1 , св5 , св6 
DROP TABLE fcst_model_store_weeks_sal_a3 PURGE;
CREATE TABLE fcst_model_store_weeks_sal_a3 AS
select  waregroup, waretradegroup, waretradesubgroup, weeknumber
,avg(sales_qty1) sales_qty1_avg, avg(sales_normirov1) sales_normirov1_avg
from  fcst_model_store_weeks_sal4
group by waregroup,  waretradegroup, waretradesubgroup, weeknumber
order by waregroup,  waretradegroup, waretradesubgroup, weeknumber
;
DROP TABLE fcst_model_store_weeks_sal5 PURGE;
CREATE TABLE fcst_model_store_weeks_sal5 AS
select f.*, nvl(f.sales_qty3,a.sales_qty1_avg) sales_qty4, nvl(f.sales_normirov3, a.sales_normirov1_avg) sales_normirov4
from fcst_model_store_weeks_sal4 f
    left join fcst_model_store_weeks_sal_a3 a on (f.weeknumber = a.weeknumber and f.waregroup = a.waregroup and f.waretradegroup = a.waretradegroup 
                                                  and f.waretradesubgroup = a.waretradesubgroup)
;
-- iv.	св1 , св5
DROP TABLE fcst_model_store_weeks_sal_a4 PURGE;
CREATE TABLE fcst_model_store_weeks_sal_a4 AS
select  waregroup, waretradegroup, weeknumber
,avg(sales_qty1) sales_qty1_avg, avg(sales_normirov1) sales_normirov1_avg
from  fcst_model_store_weeks_sal5
group by waregroup,  waretradegroup, weeknumber
order by waregroup,  waretradegroup, weeknumber
;
DROP TABLE fcst_model_store_weeks_sal6 PURGE;
CREATE TABLE fcst_model_store_weeks_sal6 AS
select f.*, nvl(f.sales_qty4,a.sales_qty1_avg) sales_qty5, nvl(f.sales_normirov4, a.sales_normirov1_avg) sales_normirov5
from fcst_model_store_weeks_sal5 f
    left join fcst_model_store_weeks_sal_a4 a on (f.weeknumber = a.weeknumber and f.waregroup = a.waregroup and f.waretradegroup = a.waretradegroup )
;
-- v.	св1, св3
DROP TABLE fcst_model_store_weeks_sal_a5 PURGE;
CREATE TABLE fcst_model_store_weeks_sal_a5 AS
select  waregroup, warecategory, weeknumber
,avg(sales_qty1) sales_qty1_avg, avg(sales_normirov1) sales_normirov1_avg
from  fcst_model_store_weeks_sal6
group by waregroup, warecategory, weeknumber
order by waregroup, warecategory, weeknumber
;
DROP TABLE fcst_model_store_weeks_sal7 PURGE;
CREATE TABLE fcst_model_store_weeks_sal7 AS
select f.*, nvl(f.sales_qty5,a.sales_qty1_avg) sales_qty6, nvl(f.sales_normirov5, a.sales_normirov1_avg) sales_normirov6
from fcst_model_store_weeks_sal6 f
    left join fcst_model_store_weeks_sal_a5 a on (f.weeknumber = a.weeknumber and f.waregroup = a.waregroup and f.warecategory = a.warecategory)
;
--  d.	Считаешь доли по неделям: доля продаж недели (отдельно для нормированной продажи, отдельно для ненормированной) к суммарным продажам по всем неделям для данной цм/магазина
--e.	Добавляешь суммарный плановый лимит в штуках на модель /магазин (одно значение по всем неделям) и домножаешь его на процент из прошлого пункта 
DROP TABLE fcst_model_store_weeks_itog PURGE;
CREATE TABLE fcst_model_store_weeks_itog AS
select s.*
,sales_qty6/sum(sales_qty6) over(partition by stylecolorid, storeid) as dola_sales_qty6
,sales_normirov6/sum(sales_normirov6) over(partition by stylecolorid, storeid) as dola_sales_normirov6
,qtypl*sales_qty6/sum(sales_qty6) over(partition by stylecolorid, storeid) as f1_pl_sales_qty6
,qtypl*sales_normirov6/sum(sales_normirov6) over(partition by stylecolorid, storeid) as f2_pl_sales_normirov6
from fcst_model_store_weeks_sal7 s
;
select * from fcst_model_store_weeks_sal7
where 1=1
--and sales_qty4 is null
--and sales_qty6 is null
and stylecolorid = '31K326XFLA-2823' and storeid = 3071
;
-- Добавляем фактические продажи
drop table fcst_model_store_weeks_itog_s purge;
create table fcst_model_store_weeks_itog_s as
select f.*
,nvl(s.sales_qty,0) as fact_sales
from fcst_model_store_weeks_itog f
 left join (
                select /*+ materialize */  a.storeid, a.stylecolorid, a.weekid,
                sum(a.qty)  sales_qty
                from shops_mod.t_forecast_weekly_clean_bills a
                group by a.storeid, a.stylecolorid, a.weekid
              ) s on (f.storeid  = s.storeid and f.stylecolorid = s.stylecolorid and f.weekid = s.weekid) -- Sales (Продажи)
;
select * from fcst_model_store_weeks_itog_s;
select * from fcst_model_store_weeks_sal2
where 1=1
--and sales_qty is null 
--and weeknumber != 35
--and STYLECOLORID in ('23005V0U-.') and storeid = 358
and STYLECOLORID in ('S20EDECT032DMX-61') and storeid = 3114 -- !

-- проверка на задвоения
select count(*) from fcst_model_store_weeks_sal
union all
select count(*) from fcst_model_store_weeks_sal2
union all
select count(*) from fcst_model_store_weeks_sal7
;
-- Оценка качества прогноза
drop table fcst_model_store_weeks_itog_sk purge;
create table fcst_model_store_weeks_itog_sk as
select a.*
,Case  when a.fact_sales = 1 and a.f1_pl_sales_qty6 < 0.5                Then 2
      when a.fact_sales = 1 and a.f1_pl_sales_qty6 >=0.5 and a.f1_pl_sales_qty6 <1  Then 1
      when a.fact_sales = 0 and a.f1_pl_sales_qty6 < 0.5                Then 1
      when a.fact_sales = 0 And a.f1_pl_sales_qty6 >=0.5 And a.f1_pl_sales_qty6 <2  Then 2
      when a.fact_sales = 0 And a.f1_pl_sales_qty6 >=2                  Then a.f1_pl_sales_qty6
      when a.fact_sales >=1 And a.f1_pl_sales_qty6 < 1                  Then a.fact_sales
      else          GREATEST(a.fact_sales, a.f1_pl_sales_qty6)/LEAST(a.fact_sales, a.f1_pl_sales_qty6)
 end koef_s_f1
 ,Case  when a.fact_sales = 1 and a.f2_pl_sales_normirov6 < 0.5                Then 2
      when a.fact_sales = 1 and a.f2_pl_sales_normirov6 >=0.5 and a.f2_pl_sales_normirov6 <1  Then 1
      when a.fact_sales = 0 and a.f2_pl_sales_normirov6 < 0.5                Then 1
      when a.fact_sales = 0 And a.f2_pl_sales_normirov6 >=0.5 And a.f2_pl_sales_normirov6 <2  Then 2
      when a.fact_sales = 0 And a.f2_pl_sales_normirov6 >=2                  Then a.f2_pl_sales_normirov6
      when a.fact_sales >=1 And a.f2_pl_sales_normirov6 < 1                  Then a.fact_sales
      else          GREATEST(a.fact_sales, a.f2_pl_sales_normirov6)/LEAST(a.fact_sales, a.f2_pl_sales_normirov6)
 end koef_s_f2
from fcst_model_store_weeks_itog_s a
;
-- Тестирование модели
select * from fcst_model_store_weeks_itog_sk;
select sum(f1_pl_sales_qty6) sum_f1, sum(f2_pl_sales_normirov6) sum_f2, sum(fact_sales) sum_sales, sum(qtypl)/44 sum_qtypl from fcst_model_store_weeks_itog_sk;
-- Макс отклонение Модель-магазин 
select storeid, waregroup, warecategory, waretradegroup, stylecolorid
, avg(koef_s_f1) avg_kf1, avg(koef_s_f2) avg_kf2, sum(f1_pl_sales_qty6) sum_f1, sum(f2_pl_sales_normirov6) sum_f2, sum(fact_sales) sum_sales 
from fcst_model_store_weeks_itog_sk
where date_ <= date'2020-02-23'
group by storeid, waregroup, warecategory, waretradegroup, stylecolorid
order by avg(koef_s_f1) desc
;
select storeid
, avg(koef_s_f1) avg_kf1, avg(koef_s_f2) avg_kf2, sum(f1_pl_sales_qty6) sum_f1, sum(f2_pl_sales_normirov6) sum_f2, sum(fact_sales) sum_sales 
from fcst_model_store_weeks_itog_sk
where date_ <= date'2020-02-23'
group by storeid
order by avg(koef_s_f1) desc
;
-- Макс отклонение Модель
select waretradegroup, count(*) from
(
select a.*, row_number() over(order by avg_kf1 desc) as rn
from
(
select stylecolorid, waregroup, warecategory, waretradegroup
, avg(koef_s_f1) avg_kf1, avg(koef_s_f2) avg_kf2, sum(f1_pl_sales_qty6) sum_f1, sum(f2_pl_sales_normirov6) sum_f2, sum(fact_sales) sum_sales 
from fcst_model_store_weeks_itog_sk
where date_ <= date'2020-02-23'
group by stylecolorid, waregroup, warecategory, waretradegroup
order by avg(koef_s_f1) desc
) a
)
where rn  <= 20
group by waretradegroup
order by count(*) desc
;
select case when sales_qty_new is null then 'dop' else 'init' end
, avg(koef_s_f1) avg_kf1, avg(koef_s_f2) avg_kf2, sum(f1_pl_sales_qty6) sum_f1, sum(f2_pl_sales_normirov6) sum_f2, sum(fact_sales) sum_sales from fcst_model_store_weeks_itog_sk
group by case when sales_qty_new is null then 'dop' else 'init' end
order by avg(koef_s_f1) desc
;
select f.*, f.stylecolorid from  fcst_model_store_weeks_itog_sk f where f.storeid in (368) order by f.storeid, f.stylecolorid, f.date_

select f.stylecolorid, waregroup, warecategory, waretradegroup,f.storeid,  f.date_, f1_pl_sales_qty6, f2_pl_sales_normirov6, fact_sales, koef_s_f1, koef_s_f2
from  fcst_model_store_weeks_itog_sk f 
where f.stylecolorid in ('W716W05-W','W716W05-B','W716W05-H','S17ETOAN001TRN-.','102535FLA-MX','RCS001CLB-BLK','102042DMX-AB','102042DMX-99','JWN0W-.','102532FLA-MX','W836W05-H') 
and f.date_ <= date'2020-02-23'
order by f.stylecolorid, f.storeid,  f.date_