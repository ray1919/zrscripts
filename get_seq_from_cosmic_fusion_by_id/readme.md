## 从COSMIC Fusion数据库中拿出ROS1基因14个融合基因序列。

1. 首先找到需要的Fusion的Translocation name; 从COSMIC的FTP下载Fusion数据表。以mysql表形式进行检索。

```
SELECT `Translocation Name`, count(*), group_concat(distinct `Fusion ID`) FID
FROM `CosmicFusionExport`
where `Fusion ID` in ("1260", "1197", "1203", "1266", "1279", "1261", "1198", "1201", "1280", "1268", "1270", "1274", "1251", "1295")
group by `Translocation Name`
order by FID;
```

2. 从COSMIC FTP下载All_COSMIC_Genes.fasta

3. 根据Translocation Name中的位置信息，拼接序列，并用|分隔融合位点。
