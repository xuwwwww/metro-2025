#!/usr/bin/env node
// manage.js — Firebase Firestore 管理 CLI
// 分類：查詢 (list, fetch)、創立 (init, create)、刪除 (clear, remove)、修改 (grant, revoke, join, kick)
// 用法：
//   node manage.js <command> [options>

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');
const yargs = require('yargs/yargs');
const { hideBin } = require('yargs/helpers');

// 讀取專案版本
const pkg = require(path.resolve(__dirname, 'package.json'));
const VERSION = pkg.version;


const ADMIN_UID = '0';
const ADMIN_PASSWORD = 'X9v$2L!z7#qT';

// 初始化 Firebase Admin SDK
const serviceAccount = require(path.resolve(__dirname, 'serviceAccountKey.json'));
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// 捷運線名稱（分支線納入主線）
const TPE_LINES = [
  '淡水信義線',
  '松山新店線', // 含小碧潭支線
  '中和新蘆線',
  '板南線',
  '文湖線',
  '環狀線'
];

async function main() {
  yargs(hideBin(process.argv))
    .scriptName('manage.js')
    .usage('Usage: $0 <command> [options]')

    // ==== 查詢 ====
    .command('list-rooms', '查詢：列出所有 chatRooms', {}, async () => {
      const snap = await db.collection('chatRooms').get();
      console.log('ChatRooms:');
      snap.docs.forEach(doc => console.log(`  - ${doc.id}: ${doc.data().name}`));
    })
    .command('list-room-ids', '查詢：列出所有聊天室 ID', {}, async () => {
      const snap = await db.collection('chatRooms').get();
      console.log('Room IDs:');
      snap.docs.forEach(doc => console.log(`  - ${doc.id}`));
    })
    .command('list-messages <roomId>', '查詢：列出某聊天室的 messages', yargs => {
      yargs.positional('roomId', { type: 'string', describe: '聊天室 ID' });
    }, async ({ roomId }) => {
      const snap = await db.collection('chatRooms').doc(roomId)
                        .collection('messages').orderBy('timestamp').get();
      console.log(`Messages in ${roomId}:`);
      snap.docs.forEach(doc => {
        const d = doc.data();
        console.log(`  - ${doc.id}: ${d.content} (by ${d.senderUid})`);
      });
    })
    .command('get-room-data <roomId> [--save]', '查詢：獲取一個聊天室的所有資料', yargs => {
      yargs.positional('roomId', { type: 'string', describe: '聊天室 ID' })
           .option('save', { type: 'boolean', describe: '儲存成 JSON 檔案' });
    }, async ({ roomId, save }) => {
      try {
        // 獲取聊天室基本資料
        const roomDoc = await db.collection('chatRooms').doc(roomId).get();
        if (!roomDoc.exists) {
          console.error(`聊天室 ${roomId} 不存在`);
          return;
        }
        
        // 獲取成員資料
        const membersSnap = await db.collection('chatRooms').doc(roomId).collection('members').get();
        const members = {};
        membersSnap.docs.forEach(doc => {
          members[doc.id] = doc.data();
        });
        
        // 獲取訊息資料
        const messagesSnap = await db.collection('chatRooms').doc(roomId).collection('messages').orderBy('timestamp').get();
        const messages = {};
        messagesSnap.docs.forEach(doc => {
          messages[doc.id] = doc.data();
        });
        
        // 組合完整資料
        const roomData = {
          roomInfo: roomDoc.data(),
          members: members,
          messages: messages
        };
        
        // 顯示資料
        console.log(`\n=== 聊天室 ${roomId} 完整資料 ===`);
        console.log('基本資訊:', JSON.stringify(roomData.roomInfo, null, 2));
        console.log(`\n成員數量: ${Object.keys(roomData.members).length}`);
        console.log('成員列表:', JSON.stringify(roomData.members, null, 2));
        console.log(`\n訊息數量: ${Object.keys(roomData.messages).length}`);
        console.log('訊息列表:', JSON.stringify(roomData.messages, null, 2));
        
        // 如果指定 --save，儲存成 JSON
        if (save) {
          const filename = `room_${roomId}_data.json`;
          fs.writeFileSync(filename, JSON.stringify(roomData, null, 2));
          console.log(`\n資料已儲存至: ${filename}`);
        }
      } catch (error) {
        console.error('獲取聊天室資料時發生錯誤:', error);
      }
    })
    .command('get-user-info <uid> [--save]', '查詢：獲取單一使用者全部資訊', yargs => {
      yargs.positional('uid', { type: 'string', describe: '使用者 UID' })
           .option('save', { type: 'boolean', describe: '儲存成 JSON 檔案' });
    }, async ({ uid, save }) => {
      try {
        const userDoc = await db.collection('users').doc(uid).get();
        if (!userDoc.exists) {
          console.error(`使用者 ${uid} 不存在`);
          return;
        }
        
        const userData = userDoc.data();
        
        // 獲取使用者加入的所有聊天室（以線名為單位）
        const userRooms = [];
        for (const roomId of userData.permissions || []) {
          const roomDoc = await db.collection('chatRooms').doc(roomId).get();
          if (roomDoc.exists) {
            userRooms.push({
              roomId: roomId,
              roomInfo: roomDoc.data()
            });
          }
        }
        
        // 組合完整使用者資料
        const completeUserData = {
          uid: uid,
          userInfo: userData,
          joinedRooms: userRooms
        };
        
        // 顯示資料
        console.log(`\n=== 使用者 ${uid} 完整資訊 ===`);
        console.log('基本資訊:', JSON.stringify(completeUserData.userInfo, null, 2));
        console.log(`\n加入的聊天室數量: ${completeUserData.joinedRooms.length}`);
        console.log('聊天室列表:', JSON.stringify(completeUserData.joinedRooms, null, 2));
        
        // 如果指定 --save，儲存成 JSON
        if (save) {
          const filename = `user_${uid}_data.json`;
          fs.writeFileSync(filename, JSON.stringify(completeUserData, null, 2));
          console.log(`\n資料已儲存至: ${filename}`);
        }
      } catch (error) {
        console.error('獲取使用者資料時發生錯誤:', error);
      }
    })
    .command('fetch-data', '查詢：匯出所有 users 與 chatRooms 成 JSON', {}, async () => {
      const usersSnap = await db.collection('users').get();
      const roomsSnap = await db.collection('chatRooms').get();
      const users = {}, rooms = {};
      usersSnap.docs.forEach(doc => users[doc.id] = doc.data());
      roomsSnap.docs.forEach(doc => rooms[doc.id] = doc.data());
      fs.writeFileSync('users.json', JSON.stringify(users, null, 2));
      fs.writeFileSync('rooms.json', JSON.stringify(rooms, null, 2));
      console.log('已匯出 users.json, rooms.json');
    })

    // ==== 創立 ====
    .command('init-admin', '創立：初始化 ADMIN 帳號並賦予所有聊天室權限', {}, async () => {
      // 建立管理者帳號，並給予所有聊天室權限
      await db.collection('users').doc(ADMIN_UID)
             .set({ permissions: TPE_LINES, password: ADMIN_PASSWORD });
      // 批次將管理者加入所有聊天室的 members 子集合
      const batch = db.batch();
      TPE_LINES.forEach(roomId => {
        const memberRef = db.collection('chatRooms').doc(roomId)
                            .collection('members').doc(ADMIN_UID);
        batch.set(memberRef, { joinedAt: admin.firestore.FieldValue.serverTimestamp() });
      });
      await batch.commit();
      console.log(`Initialized manage.js v${VERSION}`);
      console.log(`Admin UID=${ADMIN_UID}, Password=${ADMIN_PASSWORD}`);
      console.log(`Admin 已獲得所有聊天室的成員權限: ${TPE_LINES.join(', ')}`);
    })
    .command('init-rooms', '創立：初始化所有捷運線聊天室', {}, async () => {
      const batch = db.batch();
      TPE_LINES.forEach(name => {
        const ref = db.collection('chatRooms').doc(name);
        batch.set(ref, {
          name,
          createdBy: ADMIN_UID,
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
      });
      await batch.commit();
      console.log('✔已建立所有台北捷運線聊天室');
    })
    .command('create-user <uid> <username> <password>', '創立：新增使用者 (permissions=[])', yargs => {
      yargs.positional('uid', { type: 'string', describe: '使用者 UID' })
           .positional('username', { type: 'string', describe: '使用者顯示名稱' })
           .positional('password', { type: 'string', describe: '使用者密碼' });
    }, async ({ uid, username, password }) => {
      if (uid === ADMIN_UID) return console.error('無法覆寫 ADMIN');
      await db.collection('users').doc(uid).set({ 
        displayName: username,
        password: password,
        permissions: [] 
      });
      console.log(`✔ 使用者 ${uid} (${username}) 已新增`);
    })
    .command('create-room <roomId> <name>', '創立：新增單一聊天室', yargs => {
      yargs.positional('roomId', { type: 'string', describe: '聊天室 ID' })
           .positional('name', { type: 'string', describe: '聊天室顯示名稱' });
    }, async ({ roomId, name }) => {
      await db.collection('chatRooms').doc(roomId)
             .set({ name, createdBy: ADMIN_UID, createdAt: admin.firestore.FieldValue.serverTimestamp() });
      console.log(`✔ 聊天室 ${roomId}:${name} 已建立`);
    })

    // ==== 刪除 ====
    .command('clear-users', '刪除：移除所有 users (保留 ADMIN)', {}, async () => {
      const snap = await db.collection('users').get();
      const batch = db.batch();
      snap.docs.forEach(doc => { if (doc.id !== ADMIN_UID) batch.delete(doc.ref); });
      await batch.commit();
      console.log('已清除所有非 ADMIN 使用者');
    })
    .command('remove-user <uid>', '刪除：移除單一使用者', yargs => {
      yargs.positional('uid',{type:'string',describe:'使用者 UID'});
    }, async ({ uid }) => {
      if (uid === ADMIN_UID) return console.error('無法移除 ADMIN');
      await db.collection('users').doc(uid).delete();
      console.log(`✔ 使用者 ${uid} 已移除`);
    })
    .command('clear-rooms', '刪除：移除所有 chatRooms', {}, async () => {
      const snap = await db.collection('chatRooms').get();
      const batch = db.batch();
      snap.docs.forEach(doc => batch.delete(doc.ref));
      await batch.commit();
      console.log('已移除所有聊天室');
    })
    .command('remove-room <roomId>', '刪除：移除單一聊天室', yargs => {
      yargs.positional('roomId',{type:'string',describe:'聊天室 ID'});
    }, async ({ roomId }) => {
      await db.collection('chatRooms').doc(roomId).delete();
      console.log(`✔ 聊天室 ${roomId} 已移除`);
    })
    .command('clear-messages [roomId]', '刪除：清除某聊天室或全部聊天室的訊息', yargs => {
      yargs.positional('roomId',{type:'string',describe:'不給則清全部'});
    }, async ({ roomId }) => {
      const rooms = roomId
        ? [roomId]
        : await db.collection('chatRooms').listDocuments().then(ds => ds.map(d => d.id));
      for (const id of rooms) {
        const snap = await db.collection('chatRooms').doc(id).collection('messages').get();
        const batch = db.batch();
        snap.docs.forEach(d => batch.delete(d.ref));
        await batch.commit();
        console.log(`清除 ${id} 訊息`);
      }
    })

    // ==== 修改 ====
    .command('grant <uid> <roomId>', '修改：授予使用者聊天室存取權', yargs => {
      yargs.positional('uid',{type:'string',describe:'使用者 UID'})
           .positional('roomId',{type:'string',describe:'聊天室 ID'});
    }, async ({ uid, roomId }) => {
      await db.collection('users').doc(uid).update({
        permissions: admin.firestore.FieldValue.arrayUnion(roomId)
      });
      await db.collection('chatRooms').doc(roomId)
              .collection('members').doc(uid)
              .set({ joinedAt: admin.firestore.FieldValue.serverTimestamp() });
      console.log('✔ ${uid} 獲得 ${roomId} 權限');
    })
    .command('revoke <uid> <roomId>', '修改：撤銷使用者聊天室存取權', yargs => {
      yargs.positional('uid',{type:'string',describe:'使用者 UID'})
           .positional('roomId',{type:'string',describe:'聊天室 ID'});
    }, async ({ uid, roomId }) => {
      await db.collection('users').doc(uid).update({
        permissions: admin.firestore.FieldValue.arrayRemove(roomId)
      });
      await db.collection('chatRooms').doc(roomId)
              .collection('members').doc(uid).delete();
      console.log('✔ ${uid} 的 ${roomId} 權限已移除');
    })
    .command('kick <uid> <roomId>', '修改：從聊天室移除使用者', yargs => {
      yargs.positional('uid',{type:'string',describe:'使用者 UID'})
           .positional('roomId',{type:'string',describe:'聊天室 ID'});
    }, async ({ uid, roomId }) => {
      if (uid === ADMIN_UID) {
        console.error('無法移除 ADMIN 使用者');
        return;
      }
      
      // 從使用者的權限中移除聊天室
      await db.collection('users').doc(uid).update({
        permissions: admin.firestore.FieldValue.arrayRemove(roomId)
      });
      
      // 從聊天室的成員中移除使用者
      await db.collection('chatRooms').doc(roomId)
              .collection('members').doc(uid).delete();
      
      console.log(`使用者 ${uid} 已從聊天室 ${roomId} 移除`);
    })

    .demandCommand(1,'請提供指令 (用 --help 查看完整列表)')
    .help('help').alias('help','h')
    .wrap(null)
    .argv;
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
