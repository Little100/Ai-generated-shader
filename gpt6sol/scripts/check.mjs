import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve('shaders');
const programs = fs.readdirSync(root).filter(name => /\.(vsh|fsh)$/.test(name));
const errors = [];

function expand(file, chain = []) {
  const absolute = path.resolve(file);
  if (chain.includes(absolute)) {
    errors.push(`Circular include: ${[...chain, absolute].join(' -> ')}`);
    return '';
  }
  const text = fs.readFileSync(absolute, 'utf8');
  return text.replace(/^\s*#include\s+"(\/[^"]+)"\s*$/gm, (_, include) => {
    const target = path.join(root, include.slice(1));
    if (!fs.existsSync(target)) {
      errors.push(`Missing include: ${target}`);
      return '';
    }
    return expand(target, [...chain, absolute]);
  });
}

function checkBalance(source, name) {
  const lines = source.split(/\r?\n/);
  const conditions = [];
  for (const [index, line] of lines.entries()) {
    const directive = line.match(/^\s*#\s*(if|ifdef|ifndef|else|elif|endif)\b/);
    if (!directive) continue;
    const kind = directive[1];
    if (['if', 'ifdef', 'ifndef'].includes(kind)) conditions.push(index + 1);
    else if (kind === 'endif') {
      if (!conditions.pop()) errors.push(`${name}:${index + 1}: unmatched #endif`);
    } else if (!conditions.length) errors.push(`${name}:${index + 1}: unmatched #${kind}`);
    if (kind === 'if' && /^\s*#\s*if\b.*\d+\.\d+/.test(line)) {
      errors.push(`${name}:${index + 1}: floating-point preprocessor condition`);
    }
  }
  if (conditions.length) errors.push(`${name}: unclosed preprocessor condition at ${conditions.join(', ')}`);

  const code = source.replace(/\/\*[\s\S]*?\*\//g, '').replace(/\/\/[^\n]*/g, '')
    .replace(/^\s*#.*$/gm, '');
  const stack = [];
  const opening = new Map([['(', ')'], ['{', '}'], ['[', ']']]);
  for (const [index, char] of [...code].entries()) {
    if (opening.has(char)) stack.push([opening.get(char), index]);
    else if (')}]'.includes(char)) {
      const pair = stack.pop();
      if (!pair || pair[0] !== char) errors.push(`${name}: mismatched delimiter at character ${index}`);
    }
  }
  if (stack.length) errors.push(`${name}: unclosed delimiter`);
}

for (const name of programs) {
  const file = path.join(root, name);
  const source = fs.readFileSync(file, 'utf8');
  if (!source.startsWith('#version 330 compatibility\n')) errors.push(`${name}: missing GLSL version`);
  const expanded = expand(file);
  checkBalance(expanded, name);
  if (!expanded.includes('void main()')) errors.push(`${name}: missing main function`);
  if (name.startsWith('gbuffers_')) {
    const partner = name.replace(/\.(vsh|fsh)$/, (_, stage) => stage === 'vsh' ? '.fsh' : '.vsh');
    if (!programs.includes(partner)) errors.push(`${name}: missing ${partner}`);
  }
}

const required = ['shaders.properties', 'block.properties', 'lang/en_us.lang', 'lang/zh_cn.lang'];
for (const name of required) {
  if (!fs.existsSync(path.join(root, name))) errors.push(`Missing pack file: ${name}`);
}

if (errors.length) {
  for (const error of errors) console.error(error);
  process.exitCode = 1;
} else {
  console.log(`Checked ${programs.length} GLSL stages and all include paths.`);
}
