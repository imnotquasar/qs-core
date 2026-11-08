# 13 · qs-banking — Bank & ATMs

Banking on top of the core money system: **ATMs** and **bank branches** (teller
peds) for deposit/withdraw/**transfer** to another account plus a **transaction
history**. All balances are the core `cash`/`bank` accounts — this resource is only
the UI, the account numbers and the transfer/history layer.

- **Resource:** `[addons]/qs-banking`.
- **Depends on:** `qs-core`, `oxmysql`.
- **UI:** React NUI.

---

## Usage

- Walk up to any **ATM prop** and press **E** → opens the banking UI in ATM mode.
- Walk up to a **bank teller ped** (map blip **Bank**) and press **E** → opens the
  banking UI in bank mode (deposit, withdraw, transfer, history).
- The UI shows your **account number**; copying it shows a notification.

Each character gets an account number (`QS` + 9 digits) the first time they open a
bank or ATM. Transfers are validated server-side; the recipient is looked up by that
account number (spaces ignored) and can be offline (their saved bank balance is
credited). A configurable fee is charged to the sender on top of the amount.
Deposits/withdrawals are limited to one per 0.6 s and transfers to one per 1.2 s per
player.

Account numbers and transactions are persisted in `bank_accounts` /
`bank_transactions` (created by `[core]/qs-core/sql/qscore.sql`).

## Config (`config.lua`)

| Key | Default | Meaning |
|---|---|---|
| `Config.OpenKey` | `38` (E) | Interact control. |
| `Config.InteractDistance` | `1.6` | Reach to an ATM; tellers use this + 0.8 m. |
| `Config.TransferFee` | `0.0` | Fraction charged on transfers (`0` = free, `0.02` = 2%). |
| `Config.HistoryLimit` | `25` | Newest transactions returned for the history. |
| `Config.ATMModels` | 4 ATM props | List of ATM prop hashes that open the UI in ATM mode. |
| `Config.Banks` | 8 branches | Branch list: `{ coords = vec4, ped = model, scenario = string }`. |
| `Config.Blip` | `sprite 108, color 2, scale 0.6, 'Bank'` | Map blip for branches (`sprite`, `color`, `scale`, `label`). |

## Events

| Event | Side | Purpose |
|---|---|---|
| `qs-banking:server:deposit` | server | Deposit cash → bank (`amount`). |
| `qs-banking:server:withdraw` | server | Withdraw bank → cash (`amount`). |
| `qs-banking:server:transfer` | server | Transfer to another account number (`account, amount`, with fee). |
| `qs-banking:client:update` | client | Push updated balances/history (`{ cash, bank, history }`) to the NUI. |

Server callback: `qs-banking:data` → `{ cash, bank, account, history }`.

NUI callbacks: `deposit`, `withdraw`, `transfer`, `accountCopied`, `close`.

## Notes

- Money itself lives in the core (`GetMoney`/`AddMoney`/`RemoveMoney`), so any other
  resource that changes `bank`/`cash` is reflected here automatically.
- History rows store `type` (`deposit`, `withdraw`, `transfer_in`, `transfer_out`),
  `amount`, the bank `balance` after the operation and a label.
- The ATM/bank mode is only passed to the UI; the server does not check the mode or
  your distance to a bank/ATM for deposits, withdrawals or transfers.
