
# Rime YAML Custom Patch 语法指南

## 语法表格

| 操作类型       | 语法                      | 说明                         |
| -------------- | ------------------------- | ---------------------------- |
| **新增**       | `key/+:`                  | 在某个列表中追加值,自动加在末尾 |
| **删除**       | `key/-:`（不可用）        | 从列表中移除值（不可用）        |
| **全局替换**   | `key: new_value`          | 替换整个键的值                |
| **部分替换**   | `key/index/subkey: value` | 修改列表中的特定项,不影响其他项 |
| **特定行替换** | engine/filters/@12        | 替换列表中第13行的值           |
| **末尾行替换** | engine/processors/@last   | 替换列表中最后一行的值         |
| **特定行追加** | engine/filters/@before 5  | 在第6行插入新值，原值后移一行   |

注意：在进行有关特定行的操作时，请注意列表的计数是从0开始的。例如，如果想在第5行插入一个值，应该使用`@before 4`。如果要替换第5行的值，应该使用`@4`。

---

## 1. **新增值 (`/+`)**

```yaml
patch:
  schema_list/+: 
    - luna_pinyin      # 这是正确的例子：追加这个方案列表为启用状态，多个值列表即可
  schema_list/-: wubi  # 这是一个错误的例子：/-不可被使用
  engine/filters/-:
    - lua_filter@*en_spacer #这是一个错误的例子：/-不可被使用
  menu/page_size: 10   # 这是正确的例子：单独替换最下层具体的值 page_size 值，不影响其他值

  
  更多方式参考rime文档

```

# Rime YAML Patch 机制解析

## 为什么 `menu/page_size: 10` 和 `menu: { page_size: 10 }` 结果不同？

在 **Rime YAML Patch 机制** 下，`menu/page_size: 10` 和 `menu: { page_size: 10 }` **看似等价**，但 **行为是不同的**，主要原因在于 **Patch 机制的覆盖策略**。

- **`menu/page_size: 10`** 仅修改 `menu` 下的 `page_size`，不会影响 `menu` 里的其他键值。
- **`menu: { page_size: 10 }`** **会直接覆盖** `menu`，即 **清空 `menu` 下原有的所有内容**，只留下 `page_size`。

---

**假设一个段落：**

```yaml
menu:
  page_size: 10
  settings:
    font_size: 14
    color: blue

```

**正确写法（不会删除 `settings`）就是局部修改值：**

```yaml
patch:
  menu/page_size: 10
```

**错误写法（会删除 `settings`）就是全局替换：**

```yaml
patch:
  menu:
    - page_size: 10
```

**以下是常用的三种情况：**

```yaml
#整体替换
patch:
  engine:
    translators:
      - table_translator@custom_phrase  #此例会替换整个engine模块的值，只保留translators下的table_translator@custom_phrase，其他值全部删除

```

```yaml
#部分替换
patch:
  engine/translators:
    - table_translator@custom_phrase  #此例只会替换engine下的translators模块的值为table_translator@custom_phrase，translators模块的其他值全部删除，而engine其他模块的值不受影响

```

```yaml
#追加新的内容
patch:
  engine/translators/+:
    - table_translator@custom_phrase  #此例只在engine下的translators模块下新增table_translator@custom_phrase，translators模块的其他值不变，engine其他模块的值也不受影响

```

也就是说不能用/-，如果想要删除某一行

下面再用两个实际的例子来巩固一下：

```yaml
#由于下面列表值，所以你想删除某一行只能在这里注释掉，还要观察主方案是否提供了新的值，删除某一个单独的值确实是个难点
patch:
  engine/filters:
    - lua_filter@*chars_filter                     
    - lua_filter@*cold_word_drop.filter
    - lua_filter@*assist_sort                       
    - lua_filter@*autocap_filter                    
    - reverse_lookup_filter@radical_reverse_lookup  
    - lua_filter@*pro_preedit_format                
    - simplifier@emoji                            
    - simplifier@traditionalize                     
    - simplifier@mars                               
    - simplifier@chinese_english                    
    - simplifier@zrm_chaifen                        
    - lua_filter@*search@radical_pinyin            
    #- lua_filter@*en_spacer                         
    - lua_filter@*pro_comment_format                
    - uniquifier   
```

```yaml
#但是如果你想删除某一行携带值的整行，有办法了，用如下的表示即可，将现有的值清空，部署的时候整行也就不会生效了，这一行就不存在了
patch:
  custom_phrase/user_dict:
  custom_phrase/initial_quality:
```

最后还要注意一点，非常重要：

在engine模块下面的选项是有顺序的，所以想要新增一个行，需要判断添加到末尾是否可用，如果是一个引导器就不能下面这样添加，这会导致这一行排列在最后，导致功能不能使用

```yaml
#追加新的内容
patch:
  engine/translators/+:   #这种方式将把新增值自动加在列表末尾，导致功能失效
    - table_translator@custom_phrase
```

应该使用**特定行追加**  engine/translator/@before 5 意思就是放到translator下面的第6行，而原来第6行的值会移到第7行，其他的依次后移

```yaml
patch:
  engine/translator/@before 5:  #这种方式将在第5行后面新增一行，后面的行后移
    table_translator@custom_phrase   #注意前面不能加短线了，这样才是一个值，而不是一个表
  engine/translator/@5:    #这种方式将替换第6行的值
    table_translator@custom_phrase   #注意前面不能加短线了，这样才是一个值，而不是一个表
```
