const admin = require('firebase-admin');
const fs = require('fs-extra');
const path = require('path');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize Firebase Admin
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const CSV_DIR = path.join(__dirname, '../Csv');

async function importData() {
    try {
        const files = await fs.readdir(CSV_DIR);
        const csvFiles = files.filter(file => file.endsWith('.csv'));

        console.log(`Found ${csvFiles.length} CSV files to process.`);

        for (const file of csvFiles) {
            await processFile(file);
        }

        console.log('All files processed.');

    } catch (error) {
        console.error('Error importing data:', error);
    }
}

async function processFile(fileName) {
    const filePath = path.join(CSV_DIR, fileName);
    const content = await fs.readFile(filePath, 'utf8');
    const lines = content.split('\n').map(l => l.trim()).filter(l => l);

    if (lines.length < 3) {
        console.warn(`Skipping ${fileName}: Not enough lines.`);
        return;
    }

    // Line 1: Teacher Name "Alguacil Jiménez, Sergio A.;;;;;"
    // We remove trailing semicolons
    const teacherNameRaw = lines[0].split(';')[0];
    const teacherName = teacherNameRaw.replace(/"/g, '').trim();

    // Line 2: Header "/~\ ;Lunes;Martes;Miércoles;Jueves;Viernes"
    // Just validation, maybe

    // Lines 3+: Data
    // "16:00\n17:00";"APLOF\n1º SMR\n(119)";...

    // We will build a 'schedule' object
    // {
    //   profesor: "Name",
    //   horas: [
    //     {
    //       hora: "16:00-17:00",
    //       lunes: "Subject Info",
    //       martes: "Subject Info",
    //       ...
    //     }
    //   ]
    // }

    const scheduleData = [];

    for (let i = 2; i < lines.length; i++) {
        // Basic CSV splitting by semicolon, taking likely quoted newlines into account is hard with just split.
        // However, the sample showed standard "..." quoting.
        // We'll use a regex to split by semicolon that's NOT inside quotes.
        const row = splitCsv(lines[i]);

        if (row.length < 6) continue; // Expect Time + 5 days

        scheduleData.push({
            hora: cleanCell(row[0]),
            lunes: cleanCell(row[1]),
            martes: cleanCell(row[2]),
            miercoles: cleanCell(row[3]),
            jueves: cleanCell(row[4]),
            viernes: cleanCell(row[5]),
        });
    }

    // Create Document ID from filename (clean it)
    const docId = fileName.replace('.csv', '').replace(/[^a-zA-Z0-9]/g, '_');

    await db.collection('horarios').doc(docId).set({
        profesor: teacherName,
        horario: scheduleData,
        original_file: fileName,
        updated_at: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log(`Uploaded: ${teacherName} (${fileName})`);
}

function splitCsv(str) {
    // Matches: ";", but checks if we are inside quotes.
    // Actually, simplest is to use a library, but if we process line by line manually with custom format, 
    // we might get away with a regex for this specific Excel-exported style.
    // Regex to match fields:  (".*?"|[^";]+)(?=\s*;|\s*$)
    // But let's simplify: splitting by `";"` often works if fields are quoted.

    // Better approach: State machine or use a library that handles strings?
    // Since we imported 'csv-parser' in package.json, let's stick to manual split 
    // because the file structure (Header on line 2) is weird for stream parsers.

    const matches = [];
    let current = '';
    let inQuote = false;

    for (let i = 0; i < str.length; i++) {
        const char = str[i];
        if (char === '"') {
            inQuote = !inQuote;
        } else if (char === ';' && !inQuote) {
            matches.push(current);
            current = '';
        } else {
            current += char;
        }
    }
    matches.push(current);
    return matches;
}

function cleanCell(cell) {
    if (!cell) return '';
    // Remove wrapping quotes and replace internal escaped quotes
    let c = cell.trim();
    if (c.startsWith('"') && c.endsWith('"')) {
        c = c.substring(1, c.length - 1);
    }
    // Convert embedded newlines to spaces or keep them? Keep them is better.
    return c.replace(/""/g, '"');
}

importData();
