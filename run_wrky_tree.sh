#!/bin/bash
# ===============================================
# CfWRKY 系统发育树构建流程
# 工具: MAFFT + trimAl + IQ-TREE v3
# 作者: t210549
# 日期: $(date +%Y-%m-%d)
# ===============================================

# ======= 路径配置 =======
input_fa="/home/data/t210549/liuhuacheng/进化树构建/Cf_WRKY_pep_renamed.fa"
outdir="/home/data/t210549/liuhuacheng/进化树构建/20251104wrky"
prefix="CfWRKY182"

# ======= 创建输出目录 =======
mkdir -p "$outdir"
cd "$outdir"

# ======= Step 1: MAFFT 多序列比对 =======
echo "🧩 Step 1: MAFFT 多序列比对..."
if ! command -v mafft &> /dev/null; then
  echo "❌ 未检测到 MAFFT，请先安装：conda install -c bioconda mafft -y"
  exit 1
fi

mafft --localpair --maxiterate 1000 --thread 4 \
"$input_fa" > "${prefix}.aln.fa" 2> "${prefix}_mafft.log"

if [ $? -ne 0 ]; then
  echo "❌ MAFFT 运行失败，请检查 ${prefix}_mafft.log"
  exit 1
fi
echo "✅ 比对完成: ${prefix}.aln.fa"
echo "------------------------------------"


# ======= Step 2: trimAl 修剪低质量区域 =======
echo "✂️  Step 2: trimAl 修剪低质量区域..."
if ! command -v trimal &> /dev/null; then
  echo "❌ 未检测到 trimAl，请先安装：conda install -c bioconda trimal -y"
  exit 1
fi

trimal -automated1 \
-in "${prefix}.aln.fa" \
-out "${prefix}.trim.fa" \
2> "${prefix}_trimal.log"

if [ $? -ne 0 ]; then
  echo "❌ trimAl 修剪失败，请检查 ${prefix}_trimal.log"
  exit 1
fi
echo "✅ 修剪完成: ${prefix}.trim.fa"
echo "------------------------------------"


# ======= Step 3: IQ-TREE 构建系统发育树 =======
echo "🌳 Step 3: IQ-TREE 构建系统发育树..."
if ! command -v iqtree &> /dev/null; then
  echo "❌ 未检测到 IQ-TREE，请先安装：conda install -c bioconda iqtree -y"
  exit 1
fi

iqtree -s "${prefix}.trim.fa" \
-m MFP -bb 1000 -alrt 1000 -nt AUTO -seed 20251104 \
-pre "$prefix" > "${prefix}_iqtree.log" 2>&1

if [ $? -ne 0 ]; then
  echo "❌ IQ-TREE 运行失败，请检查 ${prefix}_iqtree.log"
  exit 1
fi
echo "✅ IQ-TREE 构树完成: ${prefix}.treefile"
echo "------------------------------------"


# ======= Step 4: 后处理树文件 =======
echo "🧹 Step 4: 清理树文件格式..."
cp "${prefix}.treefile" "${prefix}.raw.nwk"
sed -E 's/([0-9.]+)\/([0-9.]+)/\2/g' "${prefix}.treefile" > "${prefix}.ufb.nwk"
sed -i 's/\r//g' "${prefix}.ufb.nwk"

echo "🎉 分析完成！"
echo "📁 所有结果已保存到: $outdir"
echo "------------------------------------"
ls -lh "${outdir}" | grep "${prefix}"
