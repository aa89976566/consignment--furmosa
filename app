import React, { useMemo, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Separator } from "@/components/ui/separator";
import { Package, Store, Wallet, History, Search, AlertTriangle, CheckCircle2 } from "lucide-react";

const stores = [
  { id: "S001", name: "淡水妞妞", cycle: "月結", contact: "店長A", status: "合作中" },
  { id: "S002", name: "犬派", cycle: "月結", contact: "店長B", status: "合作中" },
  { id: "S003", name: "泡泡堂", cycle: "雙週結", contact: "店長C", status: "合作中" },
  { id: "S004", name: "星汪樂寵", cycle: "月結", contact: "店長D", status: "合作中" },
];

const products = [
  { id: "P001", name: "簡記牛肉地瓜酥50g", sku: "BEEF-50", price: 160, cost: 70 },
  { id: "P002", name: "壕大大雞排原味", sku: "CHK-OG", price: 89, cost: 30 },
  { id: "P003", name: "鴨喉嚨 30g", sku: "DUCK-TH", price: 120, cost: 45 },
  { id: "P004", name: "鴨肉蘋果 30g", sku: "DUCK-AP", price: 130, cost: 48 },
];

const rules = [
  { storeId: "S001", productId: "P001", type: "fixed", storeCommission: 60 },
  { storeId: "S001", productId: "P002", type: "fixed", storeCommission: 30 },
  { storeId: "S002", productId: "P002", type: "percent", storeCommission: 0.2 },
  { storeId: "S003", productId: "P003", type: "percent", storeCommission: 0.2 },
  { storeId: "S003", productId: "P004", type: "percent", storeCommission: 0.2 },
  { storeId: "S004", productId: "P002", type: "percent", storeCommission: 0.2 },
  { storeId: "S004", productId: "P001", type: "fixed", storeCommission: 55 },
];

const inventoryLedgerSeed = [
  { id: "L001", date: "2026-04-01", storeId: "S004", productId: "P002", type: "delivery", qty: 8, sourceNo: "DEL-001" },
  { id: "L002", date: "2026-04-01", storeId: "S004", productId: "P001", type: "delivery", qty: 5, sourceNo: "DEL-001" },
  { id: "L003", date: "2026-04-17", storeId: "S003", productId: "P003", type: "delivery", qty: 3, sourceNo: "DEL-002" },
  { id: "L004", date: "2026-04-17", storeId: "S003", productId: "P004", type: "delivery", qty: 3, sourceNo: "DEL-002" },
  { id: "L005", date: "2026-04-20", storeId: "S004", productId: "P002", type: "sale", qty: -6, sourceNo: "SALE-001" },
  { id: "L006", date: "2026-04-20", storeId: "S004", productId: "P001", type: "sale", qty: -3, sourceNo: "SALE-001" },
  { id: "L007", date: "2026-04-20", storeId: "S003", productId: "P003", type: "sale", qty: -1, sourceNo: "SALE-002" },
];

const settlementHistorySeed = [
  {
    id: "SET-2026-03-S001",
    month: "2026-03",
    storeId: "S001",
    totalQty: 7,
    storeReceivable: 270,
    brandReceivable: 653,
    status: "已結帳",
    paidAt: "2026-04-05",
  },
];

function currency(n) {
  return new Intl.NumberFormat("zh-TW", { style: "currency", currency: "TWD", maximumFractionDigits: 0 }).format(n || 0);
}

function getStoreName(storeId) {
  return stores.find((s) => s.id === storeId)?.name || "-";
}

function getProduct(productId) {
  return products.find((p) => p.id === productId);
}

function getRule(storeId, productId) {
  return rules.find((r) => r.storeId === storeId && r.productId === productId);
}

function calcSettlement(storeId, productId, qty) {
  const product = getProduct(productId);
  const rule = getRule(storeId, productId);
  if (!product || !rule) return { storeAmt: 0, brandAmt: 0 };
  const storeUnit = rule.type === "fixed" ? rule.storeCommission : product.price * rule.storeCommission;
  const brandUnit = product.price - storeUnit;
  return { storeAmt: storeUnit * qty, brandAmt: brandUnit * qty };
}

export default function JiangChongConsignmentApp() {
  const [inventoryLedger, setInventoryLedger] = useState(inventoryLedgerSeed);
  const [settlementHistory, setSettlementHistory] = useState(settlementHistorySeed);
  const [storeFilter, setStoreFilter] = useState("all");
  const [search, setSearch] = useState("");
  const [formStoreId, setFormStoreId] = useState("S001");
  const [formProductId, setFormProductId] = useState("P001");
  const [formQty, setFormQty] = useState("");
  const [entryType, setEntryType] = useState("sale");

  const inventorySummary = useMemo(() => {
    const map = new Map();
    inventoryLedger.forEach((row) => {
      const key = `${row.storeId}-${row.productId}`;
      const prev = map.get(key) || 0;
      map.set(key, prev + row.qty);
    });
    return Array.from(map.entries()).map(([key, qty]) => {
      const [storeId, productId] = key.split("-");
      const product = getProduct(productId);
      const rule = getRule(storeId, productId);
      return {
        storeId,
        storeName: getStoreName(storeId),
        productId,
        productName: product?.name || "-",
        price: product?.price || 0,
        currentStock: qty,
        status: qty <= 0 ? "售完" : qty <= 2 ? "低庫存" : "正常",
        commissionType: rule?.type === "fixed" ? "固定" : "%",
        commissionValue:
          rule?.type === "fixed"
            ? currency(rule?.storeCommission || 0)
            : `${Math.round((rule?.storeCommission || 0) * 100)}%`,
      };
    });
  }, [inventoryLedger]);

  const filteredInventory = useMemo(() => {
    return inventorySummary.filter((row) => {
      const matchStore = storeFilter === "all" ? true : row.storeId === storeFilter;
      const q = search.trim().toLowerCase();
      const matchSearch = !q || row.productName.toLowerCase().includes(q) || row.storeName.toLowerCase().includes(q);
      return matchStore && matchSearch;
    });
  }, [inventorySummary, storeFilter, search]);

  const unsettled = useMemo(() => {
    const grouped = {};
    inventoryLedger
      .filter((x) => x.type === "sale")
      .forEach((row) => {
        const month = row.date.slice(0, 7);
        const key = `${month}-${row.storeId}`;
        if (!grouped[key]) {
          grouped[key] = {
            month,
            storeId: row.storeId,
            storeName: getStoreName(row.storeId),
            totalQty: 0,
            storeReceivable: 0,
            brandReceivable: 0,
            lines: [],
          };
        }
        const qty = Math.abs(row.qty);
        const calc = calcSettlement(row.storeId, row.productId, qty);
        grouped[key].totalQty += qty;
        grouped[key].storeReceivable += calc.storeAmt;
        grouped[key].brandReceivable += calc.brandAmt;
        grouped[key].lines.push({
          productName: getProduct(row.productId)?.name || "-",
          qty,
          storeAmt: calc.storeAmt,
          brandAmt: calc.brandAmt,
        });
      });

    return Object.values(grouped).filter((g) => !settlementHistory.some((h) => h.month === g.month && h.storeId === g.storeId));
  }, [inventoryLedger, settlementHistory]);

  const dashboard = useMemo(() => {
    return {
      stores: stores.length,
      skus: products.length,
      lowStock: inventorySummary.filter((x) => x.status === "低庫存").length,
      pendingSettlement: unsettled.length,
    };
  }, [inventorySummary, unsettled]);

  const addLedgerEntry = () => {
    if (!formStoreId || !formProductId || !formQty) return;
    const qtyNumber = Number(formQty);
    const signedQty = entryType === "sale" ? -Math.abs(qtyNumber) : Math.abs(qtyNumber);
    const next = {
      id: `L${String(inventoryLedger.length + 1).padStart(3, "0")}`,
      date: new Date().toISOString().slice(0, 10),
      storeId: formStoreId,
      productId: formProductId,
      type: entryType,
      qty: signedQty,
      sourceNo: `${entryType.toUpperCase()}-${String(inventoryLedger.length + 1).padStart(3, "0")}`,
    };
    setInventoryLedger((prev) => [next, ...prev]);
    setFormQty("");
  };

  const settleNow = (item) => {
    const next = {
      id: `SET-${item.month}-${item.storeId}`,
      month: item.month,
      storeId: item.storeId,
      totalQty: item.totalQty,
      storeReceivable: item.storeReceivable,
      brandReceivable: item.brandReceivable,
      status: "已結帳",
      paidAt: new Date().toISOString().slice(0, 10),
    };
    setSettlementHistory((prev) => [next, ...prev]);
  };

  return (
    <div className="min-h-screen bg-slate-50 p-6">
      <div className="mx-auto max-w-7xl space-y-6">
        <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">匠寵寄賣管理台</h1>
            <p className="text-sm text-slate-500">前台可輸入出貨 / 銷售 / 盤點，Google Sheet 作為資料底層與查表來源</p>
          </div>
          <Badge className="rounded-full px-4 py-1 text-sm">Prototype</Badge>
        </div>

        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
          <Card className="rounded-2xl shadow-sm">
            <CardContent className="flex items-center justify-between p-5">
              <div>
                <p className="text-sm text-slate-500">合作店家</p>
                <p className="text-2xl font-bold">{dashboard.stores}</p>
              </div>
              <Store className="h-8 w-8" />
            </CardContent>
          </Card>
          <Card className="rounded-2xl shadow-sm">
            <CardContent className="flex items-center justify-between p-5">
              <div>
                <p className="text-sm text-slate-500">商品 SKU</p>
                <p className="text-2xl font-bold">{dashboard.skus}</p>
              </div>
              <Package className="h-8 w-8" />
            </CardContent>
          </Card>
          <Card className="rounded-2xl shadow-sm">
            <CardContent className="flex items-center justify-between p-5">
              <div>
                <p className="text-sm text-slate-500">低庫存</p>
                <p className="text-2xl font-bold">{dashboard.lowStock}</p>
              </div>
              <AlertTriangle className="h-8 w-8" />
            </CardContent>
          </Card>
          <Card className="rounded-2xl shadow-sm">
            <CardContent className="flex items-center justify-between p-5">
              <div>
                <p className="text-sm text-slate-500">待結帳</p>
                <p className="text-2xl font-bold">{dashboard.pendingSettlement}</p>
              </div>
              <Wallet className="h-8 w-8" />
            </CardContent>
          </Card>
        </div>

        <Tabs defaultValue="inventory" className="space-y-4">
          <TabsList className="grid w-full grid-cols-4 rounded-2xl">
            <TabsTrigger value="inventory">庫存總覽</TabsTrigger>
            <TabsTrigger value="entry">前台輸入</TabsTrigger>
            <TabsTrigger value="settlement">寄賣結帳</TabsTrigger>
            <TabsTrigger value="history">歷史訂單</TabsTrigger>
          </TabsList>

          <TabsContent value="inventory">
            <Card className="rounded-2xl shadow-sm">
              <CardHeader>
                <CardTitle>店家商品庫存 / 寄賣狀態</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="flex flex-col gap-3 md:flex-row">
                  <div className="relative flex-1">
                    <Search className="absolute left-3 top-3 h-4 w-4 text-slate-400" />
                    <Input className="pl-9" placeholder="搜尋店家或商品" value={search} onChange={(e) => setSearch(e.target.value)} />
                  </div>
                  <Select value={storeFilter} onValueChange={setStoreFilter}>
                    <SelectTrigger className="w-full md:w-56">
                      <SelectValue placeholder="選擇店家" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">全部店家</SelectItem>
                      {stores.map((store) => (
                        <SelectItem key={store.id} value={store.id}>{store.name}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div className="rounded-xl border bg-white">
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>店家</TableHead>
                        <TableHead>商品</TableHead>
                        <TableHead>售價</TableHead>
                        <TableHead>目前庫存</TableHead>
                        <TableHead>寄賣狀態</TableHead>
                        <TableHead>抽成類型</TableHead>
                        <TableHead>店家可得</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {filteredInventory.map((row, idx) => (
                        <TableRow key={idx}>
                          <TableCell>{row.storeName}</TableCell>
                          <TableCell>{row.productName}</TableCell>
                          <TableCell>{currency(row.price)}</TableCell>
                          <TableCell>{row.currentStock}</TableCell>
                          <TableCell>
                            <Badge variant={row.status === "正常" ? "default" : "secondary"}>{row.status}</Badge>
                          </TableCell>
                          <TableCell>{row.commissionType}</TableCell>
                          <TableCell>{row.commissionValue}</TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="entry">
            <div className="grid gap-4 lg:grid-cols-[1.1fr_1.4fr]">
              <Card className="rounded-2xl shadow-sm">
                <CardHeader>
                  <CardTitle>前台輸入資料</CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div>
                    <p className="mb-2 text-sm text-slate-500">輸入類型</p>
                    <Select value={entryType} onValueChange={setEntryType}>
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="sale">銷售</SelectItem>
                        <SelectItem value="delivery">補貨 / 出貨</SelectItem>
                        <SelectItem value="adjustment">盤點調整</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div>
                    <p className="mb-2 text-sm text-slate-500">店家</p>
                    <Select value={formStoreId} onValueChange={setFormStoreId}>
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {stores.map((store) => (
                          <SelectItem key={store.id} value={store.id}>{store.name}</SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                  <div>
                    <p className="mb-2 text-sm text-slate-500">商品</p>
                    <Select value={formProductId} onValueChange={setFormProductId}>
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {products.map((product) => (
                          <SelectItem key={product.id} value={product.id}>{product.name}</SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                  <div>
                    <p className="mb-2 text-sm text-slate-500">數量</p>
                    <Input type="number" placeholder="請輸入數量" value={formQty} onChange={(e) => setFormQty(e.target.value)} />
                  </div>
                  <Button className="w-full rounded-xl" onClick={addLedgerEntry}>新增紀錄</Button>
                  <p className="text-xs leading-6 text-slate-500">正式版可改成：櫃台人員只要輸入店家、商品、數量，系統自動寫回 Google Sheets 的庫存台帳。</p>
                </CardContent>
              </Card>

              <Card className="rounded-2xl shadow-sm">
                <CardHeader>
                  <CardTitle>最新交易紀錄</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="rounded-xl border bg-white">
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead>日期</TableHead>
                          <TableHead>店家</TableHead>
                          <TableHead>商品</TableHead>
                          <TableHead>類型</TableHead>
                          <TableHead>數量</TableHead>
                          <TableHead>來源單號</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {inventoryLedger.slice(0, 10).map((row) => (
                          <TableRow key={row.id}>
                            <TableCell>{row.date}</TableCell>
                            <TableCell>{getStoreName(row.storeId)}</TableCell>
                            <TableCell>{getProduct(row.productId)?.name}</TableCell>
                            <TableCell>{row.type}</TableCell>
                            <TableCell>{row.qty}</TableCell>
                            <TableCell>{row.sourceNo}</TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </div>
                </CardContent>
              </Card>
            </div>
          </TabsContent>

          <TabsContent value="settlement">
            <Card className="rounded-2xl shadow-sm">
              <CardHeader>
                <CardTitle>待結帳店家</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                {unsettled.length === 0 && (
                  <div className="rounded-xl border border-dashed p-8 text-center text-slate-500">目前沒有待結帳資料</div>
                )}
                {unsettled.map((item) => (
                  <Card key={`${item.month}-${item.storeId}`} className="rounded-2xl border bg-white shadow-none">
                    <CardContent className="p-5">
                      <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                        <div className="space-y-2">
                          <div className="flex items-center gap-2">
                            <h3 className="text-lg font-semibold">{item.storeName}</h3>
                            <Badge variant="secondary">{item.month}</Badge>
                          </div>
                          <p className="text-sm text-slate-500">總銷售 {item.totalQty} 件</p>
                          <div className="flex flex-wrap gap-6 text-sm">
                            <div>
                              <p className="text-slate-500">店家應收</p>
                              <p className="font-semibold">{currency(item.storeReceivable)}</p>
                            </div>
                            <div>
                              <p className="text-slate-500">匠寵應收</p>
                              <p className="font-semibold">{currency(item.brandReceivable)}</p>
                            </div>
                          </div>
                        </div>
                        <div className="flex gap-2">
                          <Dialog>
                            <DialogTrigger asChild>
                              <Button variant="outline" className="rounded-xl">查看明細</Button>
                            </DialogTrigger>
                            <DialogContent className="max-w-2xl rounded-2xl">
                              <DialogHeader>
                                <DialogTitle>{item.storeName}｜{item.month} 結帳明細</DialogTitle>
                              </DialogHeader>
                              <div className="rounded-xl border">
                                <Table>
                                  <TableHeader>
                                    <TableRow>
                                      <TableHead>商品</TableHead>
                                      <TableHead>數量</TableHead>
                                      <TableHead>店家可得</TableHead>
                                      <TableHead>匠寵可得</TableHead>
                                    </TableRow>
                                  </TableHeader>
                                  <TableBody>
                                    {item.lines.map((line, idx) => (
                                      <TableRow key={idx}>
                                        <TableCell>{line.productName}</TableCell>
                                        <TableCell>{line.qty}</TableCell>
                                        <TableCell>{currency(line.storeAmt)}</TableCell>
                                        <TableCell>{currency(line.brandAmt)}</TableCell>
                                      </TableRow>
                                    ))}
                                  </TableBody>
                                </Table>
                              </div>
                            </DialogContent>
                          </Dialog>
                          <Button className="rounded-xl" onClick={() => settleNow(item)}>標示已結帳</Button>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="history">
            <Card className="rounded-2xl shadow-sm">
              <CardHeader>
                <CardTitle>歷史結帳訂單</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="rounded-xl border bg-white">
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>結算單號</TableHead>
                        <TableHead>月份</TableHead>
                        <TableHead>店家</TableHead>
                        <TableHead>總銷售數</TableHead>
                        <TableHead>店家應收</TableHead>
                        <TableHead>匠寵應收</TableHead>
                        <TableHead>狀態</TableHead>
                        <TableHead>結帳日</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {settlementHistory.map((row) => (
                        <TableRow key={row.id}>
                          <TableCell>{row.id}</TableCell>
                          <TableCell>{row.month}</TableCell>
                          <TableCell>{getStoreName(row.storeId)}</TableCell>
                          <TableCell>{row.totalQty}</TableCell>
                          <TableCell>{currency(row.storeReceivable)}</TableCell>
                          <TableCell>{currency(row.brandReceivable)}</TableCell>
                          <TableCell>
                            <Badge className="gap-1"><CheckCircle2 className="h-3.5 w-3.5" />{row.status}</Badge>
                          </TableCell>
                          <TableCell>{row.paidAt}</TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>

        <Card className="rounded-2xl border-dashed bg-white/80 shadow-sm">
          <CardContent className="p-5 text-sm leading-7 text-slate-600">
            <p className="font-semibold text-slate-800">正式上線建議資料流</p>
            <Separator className="my-3" />
            <p>1. 前台輸入 → Apps Script Web App API → 寫入 Google Sheets：配送單 / 配送明細 / 庫存台帳 / 月結算 / 月結算明細。</p>
            <p>2. 查詢頁面只讀取彙整後資料，避免前台直接改 Sheet。</p>
            <p>3. 結帳按鈕寫入「月結算.status = 已結帳」，並鎖定到歷史訂單。</p>
            <p>4. 抽成支援兩種：固定 commission 與 % commission，邏輯沿用你目前的寄賣分成表。</p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
